include("src/inset_packages.jl")
include("src/constants.jl")
include("src/inset_functions.jl")
include("src/inset_data.jl")
include("src/inset_tables.jl")
include("src/inset_colors.jl")
include("src/inset_geo.jl")


f = Figure(size = (1400, 900))

    dest = conus_crs,
    xgridvisible = false, ygridvisible = false,
    xticksvisible = false, yticksvisible = false,
    xticklabelsvisible = false, yticklabelsvisible = false)
  
    
# poly!(ga, conus.geometry, color = conus.colores, strokecolor = :white, strokewidth = 0.5)
# poly!(ga, alaska.geometry, color = alaska.colores, strokecolor = :white, strokewidth = 0.5)
# poly!(ga, hawaii.geometry, color = hawaii.colores, strokecolor = :black, strokewidth = 0.5)  


ga = GeoAxis(f[1, 1:3], aspect = DataAspect(),
    dest = conus_crs,
    xgridvisible = false, ygridvisible = false,
    xticksvisible = false, yticksvisible = false,
    xticklabelsvisible = false, yticklabelsvisible = false)
  
    
# Inset: Alaska in bottom-left, 25% size of parent
alaska_inset = GeoAxis(fig[1, 1], width=Relative(0.75), height=Relative(0.75),
halign=-1, valign=0.74, dest=alaska_crs)
hidedecorations!(alaska_inset)
poly!(alaska_inset, alaska.geometry, color = alaska.colores, strokecolor = :white, strokewidth = 0.5)

    
# Inset: Hawaii in bottom-right, 18% size of parent
hawaii_inset = GeoAxis(fig[1, 1], width=Relative(0.5), height=Relative(0.5),
halign=-0.3, valign=0.3, dest=hawaii_crs)
hidedecorations!(hawaii_inset)
poly!(hawaii_inset, hawaii.geometry, color = hawaii.colores, strokecolor = :white, strokewidth = 0.5)

poly!(ga, conus.geometry, color = conus.colores, strokecolor = :white, strokewidth = 0.5)

display(f)

using GeoMakie, CairoMakie

fig = Figure(size = (1200, 800))
# Main conterminous US map
main_ax = GeoAxis(fig[1, 1]; dest=conus_crs)
# Plot the main map
poly!(main_ax, conus.geometry, color = conus.colores, strokecolor = :white, strokewidth = 0.5)
hidedecorations!(main_ax)
# Inset: Alaska in bottom-left, 25% size of parent
alaska_inset = GeoAxis(fig[1, 1], width=Relative(0.75), height=Relative(0.75),
                       halign=-1, valign=0.74, dest=alaska_crs)
hidedecorations!(alaska_inset)
poly!(alaska_inset, alaska.geometry, color = alaska.colores, strokecolor = :white, strokewidth = 0.5)

# Inset: Hawaii in bottom-right, 18% size of parent
hawaii_inset = GeoAxis(fig[1, 1], width=Relative(0.5), height=Relative(0.5),
                       halign=-0.3, valign=0.3, dest=hawaii_crs)
hidedecorations!(hawaii_inset)
poly!(hawaii_inset, hawaii.geometry, color = hawaii.colores, strokecolor = :white, strokewidth = 0.5)

fig
