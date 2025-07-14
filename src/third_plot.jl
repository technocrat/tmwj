using CairoMakie, GeoMakie, NaturalEarth

coastlines = GeoMakie.coastlines()
land = GeoMakie.land()
# Fixed version matching your code structure
using CairoMakie, GeoMakie, NaturalEarth

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

display(f)