using Pkg; Pkg.activate(@__DIR__)
using CSV, ColorSchemes, DataFrames, DataFramesMeta, 
      GeoDataFrames, GeoMakie, CairoMakie, ArchGDAL, GeoInterface

# Import specific colorschemes
const greens = colorschemes[:Greens]
const reds = colorschemes[:Reds]  
const blues = colorschemes[:Blues]

include("src/constants.jl")
include("src/utils.jl")

# Function to calculate centroids for polygons, handing both
# polygon and multipolygon geometries
function safe_centroid(geom)
    try
        # Try ArchGDAL centroid first
        cent = ArchGDAL.centroid(geom)
        return (ArchGDAL.getx(cent, 0), ArchGDAL.gety(cent, 0))
    catch e
        try
            # Fallback: use GeoInterface to get coordinates and calculate centroid manually
            coords = GeoInterface.coordinates(geom)
            if !isempty(coords) && !isempty(coords[1]) && !isempty(coords[1][1])
                # For polygons, use the first ring (exterior)
                ring_coords = coords[1][1]
                if length(ring_coords) > 0
                    # Calculate centroid as mean of coordinates
                    x_sum = sum(coord[1] for coord in ring_coords)
                    y_sum = sum(coord[2] for coord in ring_coords)
                    n = length(ring_coords)
                    return (x_sum/n, y_sum/n)
                end
            end
        catch e2
            println("Warning: Could not calculate centroid for geometry: $e2")
        end
        return (0.0, 0.0)  # Fallback coordinates
    end
end
function plot_wheat(wheat_counties::DataFrame,pic::Int,had_wheat::Int)
    if pic == 1
        ga = ga1
    elseif pic == 2
        ga = ga2
    elseif pic == 3
        ga = ga3
    elseif pic == 4
        ga = ga4
    end
    if nrow(wheat_counties) > 0
        # Calculate centroids for wheat counties
        if had_wheat == 1950
            wheat_counties.had_wheat = wheat_counties.wheat1950bu
            wheat_counties.bu = wheat_counties.wheat1950bu
        else
            wheat_counties.had_wheat = wheat_counties.wheat2017bu
            wheat_counties.bu = wheat_counties.wheat2017bu
        end
        wheat_centroids = [safe_centroid(geom) for geom in wheat_counties.geometry]
        wheat_x = [coord[1] for coord in wheat_centroids]
        wheat_y = [coord[2] for coord in wheat_centroids]
        
        # Debug: Print first few centroids
        println("First 5 centroids: ", wheat_centroids[1:min(5, end)])
        println("nrow(wheat_counties): ", nrow(wheat_counties))
        
        # Filter out invalid coordinates
        valid_indices = [i for i in 1:length(wheat_x) if wheat_x[i] != 0.0 || wheat_y[i] != 0.0]
        println("valid_indices length: ", length(valid_indices))
        
        if !isempty(valid_indices)
            valid_x = wheat_x[valid_indices]
            valid_y = wheat_y[valid_indices]
            valid_bu = wheat_counties.bu[valid_indices]
            
            # Debug: Print coordinate ranges
            println("valid_x range: ", extrema(valid_x))
            println("valid_y range: ", extrema(valid_y))
            println("valid_bu range: ", extrema(valid_bu))
            # Scale marker sizes to be reasonable (between 5 and 20)
            min_bu, max_bu = extrema(valid_bu)
            if max_bu > min_bu
                scaled_sizes = 5 .+ 15 .* (valid_bu .- min_bu) ./ (max_bu - min_bu)
            else
                scaled_sizes = fill(10, length(valid_bu))
            end
            # Plot dots colored and sized by production values
            scatter!(ga, valid_x, valid_y, color = valid_bu, markersize = scaled_sizes, marker = :circle, colormap = greens)
        end
    end
end
function lost_wheat(wheat_counties::DataFrame, pic::Int)
    if pic == 1
        ga = ga1
    elseif pic == 2
        ga = ga2
    elseif pic == 3
        ga = ga3
    elseif pic == 4
        ga = ga4
    end
    # Filter for counties that had wheat in 1950 but not in 2017
    lost_wheat_counties = subset(wheat_counties, 
    :had_wheat_1950 => ByRow(x -> x == true),
    :had_wheat_2017 => ByRow(x -> x == false)
    )
    if nrow(lost_wheat_counties) > 0
        # Calculate centroids for lost wheat counties
        wheat_centroids = [safe_centroid(geom) for geom in lost_wheat_counties.geometry]
        wheat_x = [coord[1] for coord in wheat_centroids]
        wheat_y = [coord[2] for coord in wheat_centroids]
        # Filter out invalid coordinates
        valid_indices = [i for i in 1:length(wheat_x) if wheat_x[i] != 0.0 || wheat_y[i] != 0.0]
        if !isempty(valid_indices)
            valid_x = wheat_x[valid_indices]
            valid_y = wheat_y[valid_indices]
            valid_1950_production = lost_wheat_counties.wheat1950bu[valid_indices]
            # Scale marker sizes to be reasonable (between 5 and 20)
            min_bu, max_bu = extrema(valid_1950_production)
            if max_bu > min_bu
                scaled_sizes = 5 .+ 15 .* (valid_1950_production .- min_bu) ./ (max_bu - min_bu)
            else
                scaled_sizes = fill(10, length(valid_1950_production))
            end
            # Plot dots colored and sized by 1950 production values
            scatter!(ga, valid_x, valid_y, color = valid_1950_production, markersize = scaled_sizes, marker = :circle, colormap = reds)
        end
    end
end
function gain_wheat(wheat_counties::DataFrame, pic::Int)
    if pic == 1
        ga = ga1
    elseif pic == 2
        ga = ga2
    elseif pic == 3
        ga = ga3
    elseif pic == 4
        ga = ga4
    end
    # Filter for counties that have wheat in 2017 but not in 1950
    gain_wheat_counties = subset(wheat_counties, 
    :had_wheat_1950 => ByRow(x -> x == false),
    :had_wheat_2017 => ByRow(x -> x == true)
    )
    if nrow(gain_wheat_counties) > 0
        # Calculate centroids for gained wheat counties
        wheat_centroids = [safe_centroid(geom) for geom in gain_wheat_counties.geometry]
        wheat_x = [coord[1] for coord in wheat_centroids]
        wheat_y = [coord[2] for coord in wheat_centroids]
        # Filter out invalid coordinates
        valid_indices = [i for i in 1:length(wheat_x) if wheat_x[i] != 0.0 || wheat_y[i] != 0.0]
        if !isempty(valid_indices)
            valid_x = wheat_x[valid_indices]
            valid_y = wheat_y[valid_indices]
            valid_2017_production = gain_wheat_counties.wheat2017bu[valid_indices]
            # Scale marker sizes to be reasonable (between 5 and 20)
            min_bu, max_bu = extrema(valid_2017_production)
            if max_bu > min_bu
                scaled_sizes = 5 .+ 15 .* (valid_2017_production .- min_bu) ./ (max_bu - min_bu)
            else
                scaled_sizes = fill(10, length(valid_2017_production))
            end
            # Plot dots colored and sized by 2017 production values
            scatter!(ga, valid_x, valid_y, color = valid_2017_production, markersize = scaled_sizes, marker = :circle, colormap = blues)
        end
    end
end

# Function to plot wheat production dots
function plot_wheat_dots(wheat_df::DataFrame, ga::GeoAxis, year::Int, threshold::Int=175000)
    println("Plotting wheat dots for year $year with threshold $threshold")
    println("Number of counties in dataset: ", nrow(wheat_df))
    
    counties_with_dots = 0
    
    for (i, row) in enumerate(eachrow(wheat_df))
        # Calculate centroid for positioning
        cent = safe_centroid(row.geometry)
        
        # Check if county has significant wheat production
        production_col = year == 1950 ? :wheat1950bu : :wheat2017bu
        production = row[production_col]
        
        if cent[1] != 0.0 || cent[2] != 0.0
            if production > threshold
                # Calculate number of dots based on production, but limit to prevent overcrowding
                total_dots = min(Int(floor(production / threshold)), 20)  # Max 20 dots per county
                println("County $i: $production bushels = $total_dots dots")
                
                if total_dots > 0
                    counties_with_dots += 1
                    # Create positions for all dots
                    x_positions = Float64[]
                    y_positions = Float64[]
                    
                    # Split into two rows
                    first_row_count = div(total_dots, 2)
                    second_row_count = total_dots - first_row_count
                    
                    # First row - spread dots more widely
                    if first_row_count > 0
                        if first_row_count == 1
                            x_positions = [cent[1]]
                            y_positions = [cent[2] + 0.5]
                        else
                            x_range = range(cent[1] - 1.0, cent[1] + 1.0, first_row_count)
                            for x in x_range
                                push!(x_positions, x)
                                push!(y_positions, cent[2] + 0.5)
                            end
                        end
                    end
                    
                    # Second row - spread dots more widely
                    if second_row_count > 0
                        if second_row_count == 1
                            push!(x_positions, cent[1])
                            push!(y_positions, cent[2] - 0.5)
                        else
                            x_range = range(cent[1] - 1.0, cent[1] + 1.0, second_row_count)
                            for x in x_range
                                push!(x_positions, x)
                                push!(y_positions, cent[2] - 0.5)
                            end
                        end
                    end
                    
                    # Plot all dots with better spacing
                    scatter!(ga, x_positions, y_positions, marker = '●', markersize = 1, color = :black)
                end
            end
        end
    end
    
    println("Total counties with dots: $counties_with_dots")
end

tigerline_file = "data/2024_shp/cb_2024_us_state_500k.shp"

full_geo = GeoDataFrames.read(tigerline_file)
conus_geo = subset(full_geo, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
conus_geo = subset(conus_geo, :STUSPS => ByRow(x -> x ∉ ["AK", "HI"]))


df = CSV.read("data/wheat.csv", DataFrame)
df.stcofips = lpad.(df.stcofips, 5, '0')
df.delta = df.wheat2017bu .- df.wheat1950bu
select!(df, :stcofips,  :wheat2017bu, :wheat1950bu, :delta)
rename!(df, :stcofips => :GEOID)    
df.had_wheat_1950 = df.wheat1950bu .> 0
df.had_wheat_2017 = df.wheat2017bu .> 0
wheat_counties = innerjoin(conus_geo, df, on = :GEOID => :GEOID)
select!(wheat_counties, :geometry, :GEOID, :wheat1950bu, :wheat2017bu,  
                        :delta, :had_wheat_1950, :had_wheat_2017)

wheat_1950 = subset(wheat_counties, :had_wheat_1950 => ByRow(x -> x == true))
wheat_2017 = subset(wheat_counties, :had_wheat_2017 => ByRow(x -> x == true))
wheat_2017.cum = cumsum(wheat_2017.wheat2017bu)

tigerline_file = "data/2024_shp/cb_2024_us_state_500k.shp"

full_geo = GeoDataFrames.read(tigerline_file)
conus_geo = subset(full_geo, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
conus_geo = subset(conus_geo, :STUSPS => ByRow(x -> x ∉ ["AK", "HI"]))

f = Figure(size = (1400, 1000))
Label(f[0, :], "States with counties producing more than 175,000 bushels of wheat", fontsize = 16)

ga1 = GeoAxis(f[1:4,1]; dest=conus_crs, title="1950")
ga2 = GeoAxis(f[1:4,2]; dest=conus_crs, title="2017")
hidedecorations!(ga1)
hidedecorations!(ga2)
poly!(ga1, conus_geo.geometry, color = :white, strokecolor = :lightgray, strokewidth = 0.5)
poly!(ga2, conus_geo.geometry, color = :white, strokecolor = :lightgray, strokewidth = 0.5)

# Work directly with wheat production data - no need for period strings
plot_wheat_dots(wheat_1950, ga1, 1950, 175000)  # 1950 data
plot_wheat_dots(wheat_2017, ga2, 2017, 175000)  # 2017 data


# Caption below
Label(f[3, 1], "Source: USGS: https://www.sciencebase.gov/catalog/item/5ebad68b82ce25b513618071", fontsize = 10, halign=:right)

display(f)
