using CairoMakie
using ArchGDAL
using DataFrames

# Load county shapefile
println("Loading county shapefile...")
shapefile_path = "data/cb_2023_us_county_500k.shp"
dataset = ArchGDAL.read(shapefile_path)
layer = ArchGDAL.getlayer(dataset, 0)

# Extract geometries and attributes
println("Extracting geometries and attributes...")
geometries = []
statefps = []
county_names = []

for feature in layer
    geom = ArchGDAL.getgeom(feature)
    statefp = ArchGDAL.getfield(feature, "STATEFP")
    name = ArchGDAL.getfield(feature, "NAME")
    
    push!(geometries, geom)
    push!(statefps, statefp)
    push!(county_names, name)
end

# Create DataFrame
df = DataFrame(
    geom = geometries,
    statefp = statefps,
    name = county_names
)

println("Created DataFrame with $(nrow(df)) counties")
println("Sample state FIPS codes: ", unique(df.statefp)[1:10])

# Include the plotting function
include("plot_us_counties_with_insets.jl")

# Test the plotting function
println("Testing plotting function...")
fig = plot_us_counties_with_insets_agdal_affine(df)
display(fig)

println("Plotting complete!") 