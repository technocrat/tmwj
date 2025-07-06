# SCRIPT TO MAP TRAUMA CENTERS TO COUNTIES
using Pkg; Pkg.activate()
using CairoMakie
using Colors
using ColorSchemes
using GeoInterface
using GeoMakie
using Humanize

include("src/constants.jl")
include("get_counties_geom.jl")
include("trauma_query_libpq.jl")


df = create_trauma_dataframe()      
df = subset(df, :statefp => ByRow(x -> x in VALID_STATEFPS))
# conus = VALID_STATEFPS 
# conus = setdiff(conus, ["02","15"])
# df = subset(df, :statefp => ByRow(x -> x in conus))

# # Create the figure and axis
fig = Figure(size = (1400, 800))
ga = GeoAxis(fig[1, 1];
dest               = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
title              = "US Counties: Level 1 Trauma Centers and Nearby Areas",
aspect             = DataAspect(),
xgridvisible       = false, ygridvisible = false,
xticksvisible      = false, yticksvisible = false,
xticklabelsvisible = false, yticklabelsvisible = false,
)
# Define colors for different categories
trauma_center_color = :darkblue      # Counties with trauma centers
nearby_color = :lightblue            # Counties within 50 miles of Level 1 trauma centers
other_color = :lightgray             # All other counties

# Create color vector based on trauma center status
colors = [df.is_trauma_center[i] == true ? trauma_center_color : 
          df.nearby[i] == true ? nearby_color : other_color 
          for i in eachindex(df.is_trauma_center)]

# Plot all counties at once using poly! with geometry column and color vector
poly!(ga, df.geom, color=colors, strokecolor=:black, strokewidth=0.5)

# Add legend
Legend(fig[1, 2], 
      [PolyElement(color=trauma_center_color, strokecolor=:black),
       PolyElement(color=nearby_color, strokecolor=:black),
       PolyElement(color=other_color, strokecolor=:black)],
      ["Trauma Centers", "Within 100 Miles", "Other Counties"],
      "County Categories")

# Add summary statistics
trauma_count = count(df.is_trauma_center)
nearby_count = count(df.nearby)
total_count = nrow(df)

# Create text box with statistics
text!(fig[2, 2], 
      text="Total Counties: $total_count\nTrauma Centers: $trauma_count\nNearby Counties: $nearby_count",
      align=(:left, :top),
      fontsize=12,
      color=:black)

display(fig)

# Print summary statistics
println("\nTrauma Center Mapping Summary:")
println("Total counties: $total_count")
println("Counties with trauma centers: $trauma_count")
println("Counties within 50 miles of trauma centers: $nearby_count")
println("Percentage with trauma centers: $(round(trauma_count/total_count * 100, digits=1))%")
println("Percentage within 50 miles: $(round(nearby_count/total_count * 100, digits=1))%")

println("\nMap created successfully!")




total_population = sum(df.population)
# whoops
nrow(df) - length(unique(df.geoid))
df = unique(df, :geoid)
total_population = with_commas(sum(df.population))
served = subset(df, [:is_trauma_center, :nearby] => ByRow((tc, nb) -> tc || nb))
served_population = with_commas(sum(served.population))
all_counties = with_commas(nrow(df))
served_counties = with_commas(nrow(served))
percentage_counties_served = served_counties / all_counties
percentage_served_population = Float64(served_population / total_population)

function with_commas(x)
    x = Int64.(x)
    return Humanize.digitsep.(x)
end

function percent(x::Float64)
    x = Float64(x)
    return string(round(x * 100; digits=2)) * "%"
end 

percentage_counties_served_str = percent(percentage_counties_served)
percentage_served_population_str = percent(percentage_served_population)

squib = "Of the $all_counties in the continental United States, $served_counties have a Level 1 trauma center within 50 miles, or $percentage_counties_served_str of the counties. This represents $served_population of the total population, or $percentage_served_population_str."




