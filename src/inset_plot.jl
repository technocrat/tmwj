f = Figure(size = (1400, 1000))
ga = GeoAxis(f[1, 1:3]; dest=conus_crs)
poly!(ga, conus.geometry, color = conus.colores, strokecolor = :white, strokewidth = 0.5)
hidedecorations!(ga)
alaska_inset = GeoAxis(f[1, 1:3], width=Relative(0.75), height=Relative(0.75),
                       halign=-1, valign=0.75, dest=alaska_crs)
hidedecorations!(alaska_inset)
poly!(alaska_inset, alaska.geometry, color = alaska.colores, strokecolor = :white, strokewidth = 0.5)
hawaii_inset = GeoAxis(f[1, 1:3], width=Relative(0.5), height=Relative(0.5),
                       halign=-0.3, valign=0.3, dest=hawaii_crs)
hidedecorations!(hawaii_inset)
poly!(hawaii_inset, hawaii.geometry, color = hawaii.colores, strokecolor = :white, strokewidth = 0.5)
