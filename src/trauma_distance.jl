using ArchGDAL
using CSV
using DataFrames
using Distances
using GeoDataFrames
using GeometryBasics

# Load trauma center data
df = CSV.read("data/trauma_centers.csv", DataFrame)
df.geoid = lpad.(df.geoid, 5, "0")
df.statefp = lpad.(df.statefp, 2, "0")
select!(df, :geoid, :population, :is_trauma_center, :nearby, :statefp)
include("src/constants.jl") 
# Clean up nearby data
df.nearby[df.is_trauma_center] .= false
tigerline_file = "data/2024_shp/cb_2024_us_county_500k.shp"
full_geo = GeoDataFrames.read(tigerline_file)
conus_geo = subset(full_geo, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
conus_geo = subset(conus_geo, :STUSPS => ByRow(x -> x ∉ ["AK", "HI"]))
df   = innerjoin(conus_geo, df, on = :GEOID => :geoid) 
df = subset(df, :geoid, :geometry:is_trauma_center => ByRow(x -> x == true))
select!(df, :GEOID, :geometry, :population,:is_trauma_center,:nearby)
# df.colores = [df.is_trauma_center[i] === true ? trauma_center_color : 
# df.nearby[i] === true ? nearby_color : other_color 
# for i in eachindex(df.is_trauma_center)]
using ArchGDAL
using DataFrames
using Distances
using GeometryBasics


using ArchGDAL
using DataFrames
using Distances
using GeometryBasics

# Assuming you have your joined dataframe 'df' with geometry column and trauma center indicator
# Let's call the trauma center indicator column 'has_trauma_center' (boolean)

# Main function to analyze proximity of non-trauma counties to trauma centers
function analyze_non_trauma_county_proximity(df::DataFrame, distance_threshold_miles::Float64 = 50.0)
    # Convert miles to km for calculation
    distance_threshold_km = distance_threshold_miles * 1.609344
    
    # Separate counties with and without trauma centers
    trauma_counties = df[df.is_trauma_center .== true, :]
    non_trauma_counties = df[df.is_trauma_center .== false, :]
    
    println("Counties with trauma centers: $(nrow(trauma_counties))")
    println("Counties without trauma centers: $(nrow(non_trauma_counties))")
    
    # Calculate centroids for trauma center counties (lon, lat)
    trauma_centroids = []
    for geom in trauma_counties.geometry
        centroid = ArchGDAL.centroid(geom)
        lon = ArchGDAL.getx(centroid, 0)
        lat = ArchGDAL.gety(centroid, 0)
        push!(trauma_centroids, (lon, lat))
    end
    
    # Analyze ALL non-trauma counties for proximity to trauma centers
    result_counties = copy(non_trauma_counties)
    distances_km = Float64[]
    distances_miles = Float64[]
    within_threshold = Bool[]
    nearest_trauma_idx = Int[]
    
    for geom in non_trauma_counties.geometry
        # Calculate centroid of current non-trauma county
        centroid = ArchGDAL.centroid(geom)
        county_lon = ArchGDAL.getx(centroid, 0)
        county_lat = ArchGDAL.gety(centroid, 0)
        
        # Find minimum distance to any trauma center using geodesic distance
        min_distance_km = Inf
        closest_trauma_idx = 0
        
        for (t_idx, (trauma_lon, trauma_lat)) in enumerate(trauma_centroids)
            dist_km = haversine_distance_km(county_lon, county_lat, trauma_lon, trauma_lat)
            if dist_km < min_distance_km
                min_distance_km = dist_km
                closest_trauma_idx = t_idx
            end
        end
        
        # Store results for this county
        push!(distances_km, min_distance_km)
        push!(distances_miles, km_to_miles(min_distance_km))
        push!(within_threshold, min_distance_km <= distance_threshold_km)
        push!(nearest_trauma_idx, closest_trauma_idx)
    end
    
    # Add new columns to result DataFrame
    result_counties[!, :distance_to_nearest_trauma_km] = distances_km
    result_counties[!, :distance_to_nearest_trauma_miles] = distances_miles
    result_counties[!, :within_50_miles_of_trauma] = within_threshold
    result_counties[!, :nearest_trauma_county_idx] = nearest_trauma_idx
    
    # Print summary
    within_count = sum(within_threshold)
    outside_count = length(within_threshold) - within_count
    
    println("\nSUMMARY:")
    println("Non-trauma counties within $distance_threshold_miles miles of a trauma center: $within_count")
    println("Non-trauma counties beyond $distance_threshold_miles miles of a trauma center: $outside_count") 
    println("Total non-trauma counties analyzed: $(within_count + outside_count)")
    println("Percentage with nearby trauma access: $(round(within_count/length(within_threshold)*100, digits=1))%")
    
    return result_counties
end

# Alternative approach using spatial indexing for better performance with large datasets
function calculate_county_proximity_optimized(df::DataFrame, distance_threshold_miles::Float64 = 50.0)
    distance_threshold_m = distance_threshold_miles * 1609.344
    
    trauma_counties = df[df.is_trauma_center .== true, :]
    non_trauma_counties = df[df.is_trauma_center .== false, :]
    
    # Pre-calculate all centroids
    all_centroids = Dict{Int, Tuple{Float64, Float64}}()
    
    # Trauma center centroids
    trauma_centroids = Dict{Int, Tuple{Float64, Float64}}()
    for (idx, geom) in enumerate(trauma_counties.geometry)
        centroid = ArchGDAL.centroid(geom)
        x, y = ArchGDAL.getx(centroid, 0), ArchGDAL.gety(centroid, 0)
        trauma_centroids[idx] = (x, y)
    end
    
    # Find nearby counties using vectorized operations where possible
    results = []
    
    for (idx, geom) in enumerate(non_trauma_counties.geometry)
        centroid = ArchGDAL.centroid(geom)
        county_point = (ArchGDAL.getx(centroid, 0), ArchGDAL.gety(centroid, 0))
        
        # Calculate distances to all trauma centers
        distances = [euclidean(county_point, tc) for tc in values(trauma_centroids)]
        min_dist_idx = argmin(distances)
        min_distance = distances[min_dist_idx]
        
        if min_distance <= distance_threshold_m
            push!(results, (
                county_idx = idx,
                min_distance_m = min_distance,
                min_distance_miles = min_distance / 1609.344,
                nearest_trauma_idx = min_dist_idx
            ))
        end
    end
    
    # Create result DataFrame
    if length(results) > 0
        result_indices = [r.county_idx for r in results]
        nearby_counties = non_trauma_counties[result_indices, :]
        
        nearby_counties[!, :distance_to_nearest_trauma_m] = [r.min_distance_m for r in results]
        nearby_counties[!, :distance_to_nearest_trauma_miles] = [r.min_distance_miles for r in results]
        nearby_counties[!, :nearest_trauma_county_idx] = [r.nearest_trauma_idx for r in results]
        
        return nearby_counties
    else
        return DataFrame()  # Return empty DataFrame if no counties found
    end
end

# Haversine formula for geodesic distance calculation
function haversine_distance_km(lon1, lat1, lon2, lat2)
    R = 6371.0  # Earth's radius in km
    
    dlat = deg2rad(lat2 - lat1)
    dlon = deg2rad(lon2 - lon1)
    
    a = sin(dlat/2)^2 + cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dlon/2)^2
    c = 2 * atan(sqrt(a), sqrt(1-a))
    
    return R * c
end

# Convert km to miles
km_to_miles(km) = km * 0.621371

# Usage example:
# nearby_counties = calculate_county_proximity_optimized(your_dataframe, 50.0)
# println("Found $(nrow(nearby_counties)) counties within 50 miles of trauma centers")
# Usage example:
analyzed_counties = analyze_non_trauma_county_proximity(df, 50.0)

# Verify the counts
println("Within 50 miles: ", sum(analyzed_counties.within_50_miles_of_trauma))
println("Beyond 50 miles: ", sum(.!analyzed_counties.within_50_miles_of_trauma))


