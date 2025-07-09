# Example demonstrating the updated scalebar functionality
include("src/utils.jl")

# Create a simple map to test the scalebars
fig = Figure(size = (1200, 800))
# conus_scalebar_example.jl
# Complete working example: Conterminous U.S. map with a professional scalebar



# Approximate bounding box for the conterminous U.S.
# Longitude: -125 to -66, Latitude: 24 to 50
lons = [-125.0, -66.0]
lats = [24.0, 50.0]

# Create a figure and GeoAxis
fig = Figure(size = (1200, 800))
ax = GeoAxis(fig[1, 1], dest = "+proj=longlat +datum=WGS84")

# Auto-calculate axis limits with margin
autolims!(ax, lons, lats; margin=0.05)

# Optionally, plot a rectangle for the US bounding box
poly!(ax, [lons[1], lons[2], lons[2], lons[1], lons[1]],
          [lats[1], lats[1], lats[2], lats[2], lats[1]],
          color = (:lightgray, 0.2), strokecolor=:black, strokewidth=1)

# Add a sample point (center of US)
scatter!(ax, [-96.0], [37.5], color=:red, markersize=20)

# Map width in degrees and km (approximate at mid-latitude)
map_width_degrees = lons[2] - lons[1]  # 59
map_width_km = 4500  # Approximate width of CONUS in km

# Choose a break for the scalebar (e.g., 500 km)
scalebar_length = 500  # You can change to any of the specified breaks

# Place the scalebar at the bottom left
add_scalebar_with_box!(ax, lons[1] + 2, lats[1] + 1, scalebar_length, map_width_degrees, map_width_km, unit=:miles)

# Add a north arrow at the top right
add_fancy_north_arrow!(ax, lons[2] - 2, lats[2] - 1, 2.0)

# Add a title
Label(fig[0, 1], "Conterminous U.S. with Professional Scalebar", fontsize=24)

# Add a legend for the scalebar breaks
legend_text = """
Scalebar Breaks: [50, 100, 250, 500, 1000, 2000, 3000] km
Change the 'scalebar_length' variable to use a different break.
"""
Label(fig[2, 1], legend_text, fontsize=14, halign=:left, valign=:top)

display(fig)
