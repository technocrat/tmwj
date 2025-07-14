using Pkg; Pkg.activate()
using CairoMakie
using CSV
using DataFrames
using GeoDataFrames
using GeoMakie
using HTTP

# Load the shapefile
gdf = GeoDataFrames.read("data/cb_2018_us_state_500k.shp")

# Define acela correctly as individual state codes
acela = ["ME", "NH", "VT", "MA", "CT", "RI", "NY", "NJ", "PA", "MD", "DE", "DC", "VA"]

# This should now work without the method error
acela_states = subset(gdf, :STUSPS => ByRow(x -> x in acela))

println("Success! Found $(nrow(acela_states)) Acela corridor states:")
println(acela_states.STUSPS)

# Test that we can create a simple plot
fig = Figure(size = (800, 600))
ga = GeoAxis(fig[1, 1])
poly!(ga, acela_states.geometry, color = :lightblue, strokecolor = :black, strokewidth = 1)
display(fig)

println("\nAll packages working correctly!") 