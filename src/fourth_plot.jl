using Pkg
Pkg.activate(@__DIR__)

using CairoMakie, GeoMakie, NaturalEarth

coastlines = GeoMakie.coastlines()
land = GeoMakie.land()


# Get the required data
land = GeoMakie.land()
coastlines = GeoMakie.coastlines()

# Create figure
f = Figure(size = (1200, 800), backgroundcolor = :lightblue)

# Map spanning multiple columns
ga = GeoAxis(f[1, 1:2], dest = "+proj=eqearth")

n_polygons = length(land)
color_values = (1:n_polygons) .* (1.25 / n_polygons)

# Plot all polygons with blue to red colormap
poly_plot = poly!(ga, land, 
    color = color_values,
    colormap = :temperaturemap,
    strokecolor = :black,
    strokewidth = 0.5
)

lines!(ga, coastlines, color = :black, label = "Coastlines")

# Legend to the right - specify the plot object, colormap, and limits


# Title spanning full width
Label(f[0, :], "Global Climate Analysis", fontsize = 20)

# Caption below
Label(f[2, :], "Source: Climate Data Analysis", fontsize = 12)

# Legend in dedicated column
cb = Colorbar(f[1, 3], 
    poly_plot,  # Reference the plot object
    label = "Temperature (°C) Increase from 2000"
)

# Time series below spanning all columns, using a secondary axis
ax_ts = Axis(f[2:3, 1:3], xlabel = "Year", ylabel = "Global Mean Temperature")

# Create non-uniform increase from 0 in 2000 to 0.9
years = 2000:2024
# Non-linear progression - starts slow, accelerates
temperature_increase = 0.9 * ((years .- 2000) ./ 24) .^ 1.5

lines!(ax_ts, years, temperature_increase, 
    color = :red, 
    linewidth = 3,
    label = "Temperature Anomaly (°C)"
)

# Add some styling to the time series
ax_ts.limits = ((1999, 2025), (-0.1, 1.0))
axislegend(ax_ts, position = :lt)
# Relative sizes (fractions of available space)
colsize!(f.layout, 1, Relative(0.9))  # Map: 80% of width
colsize!(f.layout, 2, Relative(0.1))  # Colorbar: 20% of width
display(f)

# # Fixed sizes (absolute units)
# colsize!(f.layout, 1, Fixed(600))  # Map: 600 units wide
# colsize!(f.layout, 2, Fixed(80))   # Colorbar: 80 units wide

# # Relative sizes (fractions of available space)
# colsize!(f.layout, 1, Relative(0.8))  # Map: 80% of width
# colsize!(f.layout, 2, Relative(0.2))  # Colorbar: 20% of width

# Auto sizing with weights
# colsize!(f.layout, 1, Auto(3))  # Map gets 3x more space
# colsize!(f.layout, 2, Auto(1))  # Colorbar gets 1x space


# save("plot_4.pdf", f)