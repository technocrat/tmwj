include("src/inset_packages.jl")
include("src/constants.jl")
include("src/inset_functions.jl")
include("src/inset_data.jl")
include("src/inset_tables.jl")
include("src/inset_colors.jl")
include("src/inset_geo.jl")


# Create figure with proper aspect control
f = Figure(size = (1400, 900))
    
# Create an Axis instead of GeoAxis for better control
ga = GeoAxis(f[1, 1:3], aspect = DataAspect(),
    xgridvisible = false, ygridvisible = false,
    xticksvisible = false, yticksvisible = false,
    xticklabelsvisible = false, yticklabelsvisible = false)
    
poly!(ga, conus_geo.geometry, color = conus_geo.colores, strokecolor = :white, strokewidth = 0.5)
viz!(ga, alaska_inset.geometry, color = alaska_colors, strokecolor = :white, strokewidth = 0.5)
viz!(ga, hawaii_inset.geometry, color = hawaii_colors, strokecolor = :white, strokewidth = 0.5)  



display(f)