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

# Function to plot wheat production dots
function plot_wheat_dots(wheat_df::DataFrame, ga::GeoAxis, year::Int, threshold::Int=3000000, dotsize::Float64=1)
    counties_with_dots = 0
    
    for (i, row) in enumerate(eachrow(wheat_df))
        # Calculate centroid for positioning
        cent = safe_centroid(row.geometry)
        
        # Check if county has significant wheat production
        production_col = year == 1950 ? :wheat1950bu : :wheat2017bu
        production = row[production_col]
        
        if cent[1] != 0.0 || cent[2] != 0.0
            if production > threshold
                # Calculate number of dots based on production
                total_dots = Int(floor(production / threshold))
                
                if total_dots > 0
                    counties_with_dots += 1
                    # Create positions for all dots
                    x_positions = Float64[]
                    y_positions = Float64[]
                    
                    # Split into two rows
                    first_row_count = div(total_dots, 2)
                    second_row_count = total_dots - first_row_count
                    
                    # First row - dots closer together for coalescence
                    if first_row_count > 0
                        if first_row_count == 1
                            x_positions = [cent[1]]
                            y_positions = [cent[2] + 0.08]  # Reduced spacing
                        else
                            x_range = range(cent[1] - 0.12, cent[1] + 0.12, first_row_count)  # Reduced range
                            for x in x_range
                                push!(x_positions, x)
                                push!(y_positions, cent[2] + 0.08)  # Reduced spacing
                            end
                        end
                    end
                    
                    # Second row - dots closer together for coalescence
                    if second_row_count > 0
                        if second_row_count == 1
                            push!(x_positions, cent[1])
                            push!(y_positions, cent[2] - 0.08)  # Reduced spacing
                        else
                            x_range = range(cent[1] - 0.12, cent[1] + 0.12, second_row_count)  # Reduced range
                            for x in x_range
                                push!(x_positions, x)
                                push!(y_positions, cent[2] - 0.08)  # Reduced spacing
                            end
                        end
                    end
                    
                    # Plot all dots with larger markersize for coalescence
                    scatter!(ga, x_positions, y_positions, marker = '●', markersize = dotsize, color = :black)  # Increased from 4 to 6
                end
            end
        end
    end
    
end

county_shapefile = "data/2024_shp/cb_2024_us_county_500k.shp"
full_counties = GeoDataFrames.read(county_shapefile)
conus_counties = subset(full_counties, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
conus_counties = subset(conus_counties, :STUSPS => ByRow(x -> x ∉ ["AK", "HI"]))
state_shapefile = "data/2024_shp/cb_2024_us_state_500k.shp"
full_states = GeoDataFrames.read(state_shapefile)
conus_states = subset(full_states, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
conus_states = subset(conus_states, :STUSPS => ByRow(x -> x ∉ ["AK", "HI"]))
df = CSV.read("data/wheat.csv", DataFrame)
df.stcofips = lpad.(df.stcofips, 5, '0')
df.delta = df.wheat2017bu .- df.wheat1950bu
select!(df, :stcofips,  :wheat2017bu, :wheat1950bu, :delta)
rename!(df, :stcofips => :GEOID)    
df.had_wheat_1950 = df.wheat1950bu .> 0
df.had_wheat_2017 = df.wheat2017bu .> 0
wheat_counties = innerjoin(conus_counties, df, on = :GEOID => :GEOID)
select!(wheat_counties, :geometry, :GEOID, :wheat1950bu, :wheat2017bu,  
                        :delta, :had_wheat_1950, :had_wheat_2017)
wheat_1950 = subset(wheat_counties, :had_wheat_1950 => ByRow(x -> x == true))
wheat_2017 = subset(wheat_counties, :had_wheat_2017 => ByRow(x -> x == true))
squib1 = "In 1950 " * with_commas(nrow(wheat_1950)) * " counties produced " * with_commas(sum(wheat_1950.wheat1950bu)) * " bushels of wheat in the United States, and in 2017, " * with_commas(nrow(wheat_2017)) * " counties produced " * with_commas(sum(wheat_2017.wheat2017bu)) * " bushels of wheat."



# Sort by production (highest first)
sort!(wheat_1950, :wheat1950bu, rev=true)
sort!(wheat_2017, :wheat2017bu, rev=true)

# Calculate cumulative sums
wheat_1950.cum = cumsum(wheat_1950.wheat1950bu)
wheat_2017.cum = cumsum(wheat_2017.wheat2017bu)

# Calculate 80% thresholds
eighty_1950 = 0.8 * sum(wheat_1950.wheat1950bu)
eighty_2017 = 0.8 * sum(wheat_2017.wheat2017bu)

# Keep rows that contribute to the first 80% (cumsum <= threshold)
subset!(wheat_1950, :cum => ByRow(x -> x <= eighty_1950))
subset!(wheat_2017, :cum => ByRow(x -> x <= eighty_2017))

min_1950 = minimum(wheat_1950.wheat1950bu)
min_2017 = minimum(wheat_2017.wheat2017bu)
cutoff_1950 = with_commas(min_1950)
cutoff_2017 = with_commas(min_2017)

squib2 = "Eighty percent of the wheat produced in 1950 was produced in " * with_commas(nrow(wheat_1950)) * " counties, and in 2017, eighty percent of the wheat produced was produced in " * with_commas(nrow(wheat_2017)) * " counties."

f = Figure(size = (1400, 800))  # Reduced height for better proportions
Label(f[0, :], "States with counties responsible for 80% of US wheat production in 1950 and 2017", fontsize = 16)

# Create axes with minimal spacing
ga1 = GeoAxis(f[1,1]; dest=conus_crs, title="1950: Each dot represents $cutoff_1950 bushels")
ga2 = GeoAxis(f[2,1]; dest=conus_crs, title="2017: Each dot represents $cutoff_2017 bushels")

# Remove decorations and set minimal margins
hidedecorations!(ga1)
hidedecorations!(ga2)

# Set the column and row gaps to minimal values
colgap!(f.layout, 5)  # Minimal column gap
rowgap!(f.layout, 5)  # Minimal row gap

poly!(ga1, conus_states.geometry, color = :white, strokecolor = :lightgray, strokewidth = 0.5)
poly!(ga2, conus_states.geometry, color = :white, strokecolor = :lightgray, strokewidth = 0.5)


plot_wheat_dots(wheat_1950, ga1, 1950, min_1950, 2.0)  # 1950 data
plot_wheat_dots(wheat_2017, ga2, 2017, min_2017, 2.0)  # 2017 data

# Caption below with smaller font and tighter spacing
Label(f[3, 1], "Source: USGS: https://www.sciencebase.gov/catalog/item/5ebad68b82ce25b513618071", 
      fontsize = 9, halign=:left)  # Reduced font size

# Tighten the layout
resize_to_layout!(f)

display(f)



tab = DataFrame(
           year = [1950, 2017, "Change"],
           counties = [nrow(wheat_1950), nrow(wheat_2017), nrow(wheat_2017) - nrow(wheat_1950)],
           wheat_produced = [sum(wheat_1950.wheat1950bu), sum(wheat_2017.wheat2017bu), sum(wheat_2017.wheat2017bu) - sum(wheat_1950.wheat1950bu)],
           eighty_percent = [nrow(wheat_1950), nrow(wheat_2017), nrow(wheat_2017) - nrow(wheat_1950)]
       )

    pretty_table(tab,
    backend = Val(:text),
    header = ["Year", "Counties", "Bushels", "Top 80%"],
    alignment = [:l, :r, :r, :r],
    body_hlines = [2],
    title = "Wheat Production in the United States in 1950 and 2017"
    )
       