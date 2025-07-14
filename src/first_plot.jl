using CairoMakie, GeoMakie, NaturalEarth

coastlines = GeoMakie.coastlines()
land = GeoMakie.land()



# Basic figure container reation
f = Figure(size = (800, 600), backgroundcolor = :lightblue)

# Elements positioned using array-like indexing
ga = GeoAxis(f[1, 1])
poly!(ga, land, color = :tan, label = "Land")
poly!(ga, coastlines, color = :black, label = "Coastlines")

Legend(f[1, 2], ga)
display(f)
save("plot_1.pdf", f)