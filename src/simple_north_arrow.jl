using CairoMakie

# Create a simple north arrow function
function draw_north_arrow(ax, x, y; size=0.1, color=:black)
    # Arrow shaft (vertical line)
    shaft_length = size * 0.8
    lines!(ax, [x, x], [y, y + shaft_length], color=color, linewidth=3)
    
    # Arrow head (triangle pointing up)
    head_width = size * 0.3
    head_height = size * 0.2
    arrow_head = [
        (x, y + shaft_length + head_height),  # top point
        (x - head_width/2, y + shaft_length), # bottom left
        (x + head_width/2, y + shaft_length)  # bottom right
    ]
    poly!(ax, arrow_head, color=color)
    
    # "N" label
    text!(ax, "N", position=(x, y + shaft_length + head_height + size*0.1), 
          align=(:center, :bottom), fontsize=14, color=color)
end

# Example usage with your map
f = Figure(size=(1000, 700))

# Your existing GeoAxis setup
ga = GeoAxis(f[1, 1:3];
    dest = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
    aspect = DataAspect(),
    xgridvisible = false, ygridvisible = false,
    xticksvisible = false, yticksvisible = false,
    xticklabelsvisible = false, yticklabelsvisible = false,
)

# Add your map data here (commented out since we don't have the data in this example)
# poly!(ga, df.geom, color=colores, strokecolor=:white, strokewidth=0.5)

# Add north arrow in the top-left corner of the map
# Using data coordinates (adjust these to fit your map bounds)
draw_north_arrow(ga, -2.1e6, 1.7e6, size=1e5, color=:black)

# Add scale bar
scale_length_m = 80467.2  # 50 miles in meters
x0, y0 = -2.2e6, -1.6e6
x1 = x0 + scale_length_m
lines!(ga, [x0, x1], [y0, y0], color=:black, linewidth=3)
text!(ga, "50 mi", position=((x0 + x1)/2, y0 - 5e4), align=(:center, :top), fontsize=12)

f 