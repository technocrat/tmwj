using Pkg; Pkg.activate()
using DataFrames
using LibPQ
using ArchGDAL
using GeoInterface
using CairoMakie
using Colors
using ColorSchemes
using GeoMakie
using Humanize

include("src/constants.jl")
include("get_counties_geom.jl")     # this is the file that contains the function to get the county geometries
include("trauma_query_libpq.jl")  

# Get county geometries
df = get_counties_geom() 

df = create_trauma_dataframe()     
# # remove overseas territories
df = subset(df, :statefp => ByRow(x -> x in VALID_STATEFPS))


# Transformation parameters (adjust these based on your projection)
# alaska_params = (scale_x=0.05, scale_y=0.05, translate_x=160.0, translate_y=-40.0)
# hawaii_params = (scale_x=5.0, scale_y=5.0, translate_x=55.0, translate_y=5.0)




# # Create the figure and axis
fig = Figure(size = (1400, 800))
ga = GeoAxis(fig[1, 1];
dest               = "+proj=longlat +datum=WGS84",
title              = "US Counties: Level 1 Trauma Centers and Nearby Areas",
aspect             = DataAspect(),
xgridvisible       = false, ygridvisible = false,
xticksvisible      = false, yticksvisible = false,
xticklabelsvisible = false, yticklabelsvisible = false,
)
# Define colors for different categories
# trauma_center_color = :darkblue      # Counties with trauma centers
# nearby_color = :lightblue            # Counties within 50 miles of Level 1 trauma centers
# other_color = :lightgray             # All other counties

# # Create color vector based on trauma center status
# colors = [row.is_trauma_center == true ? trauma_center_color : 
#           row.nearby == true ? nearby_color : other_color 
#           for row in eachrow(df)]

# Plot all counties at once using poly! with geometry column and color vector
# Try plotting just first few counties to test
println("Attempting to plot first 5 counties...")
try
    poly!(ga, df.geom, color=:white, strokecolor=:black, strokewidth=0.5)
    println("First 5 counties plotted successfully")
catch e
    println("Error plotting: ", e)
end

# If that works, uncomment this to plot all counties:
# poly!(ga, df.geom, color=:white, strokecolor=:black, strokewidth=0.5)
# Add legend
# Legend(fig[1, 2], 
#       [PolyElement(color=trauma_center_color, strokecolor=:black),
#        PolyElement(color=nearby_color, strokecolor=:black),
#        PolyElement(color=other_color, strokecolor=:black)],
#       ["Trauma Centers", "Within 100 Miles", "Other Counties"],
#       "County Categories")



display(fig)