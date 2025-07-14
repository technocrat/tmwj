using CairoMakie, GeoMakie, NaturalEarth

coastlines = GeoMakie.coastlines()
land = GeoMakie.land()

# Basic figure container creation
f = Figure(size = (800, 600), backgroundcolor = :lightblue)

# Elements positioned using array-like indexing
ga = GeoAxis(f[1:3, 1])
poly!(ga, land, color = :tan, label = "Land")
poly!(ga, coastlines, color = :black, label = "Coastlines")


# Title spanning full width
Label(f[0, :], "Global Climate Analysis", fontsize = 20)

# Legend to the right
cb = Colorbar(f[1:3, 2], label = "Data Values")

# Caption below
Label(f[4, :], "Source: Chapman, D.L. (2025). Climate Forensics", fontsize = 12)
display(f)
# save("plot_3.pdf", f)