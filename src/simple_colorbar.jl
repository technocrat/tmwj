using CairoMakie
using ColorBrewer

"""
    simple_colorbar(palette_name::String, n_colors::Int)

Display a discrete vertical colorbar using ColorBrewer palettes.

# Arguments
- `palette_name::String`: Name of the ColorBrewer palette (e.g., "Greens", "Blues", "Reds")
- `n_colors::Int`: Number of discrete colors to display, must be in range 1:12

# Examples
```julia
plot_colorbar("Greens", 5)
plot_colorbar("Blues", 9)
plot_colorbar("RdYlBu", 7)

```
"""
function plot_colorbar(palette_name::String, n_colors::Int)
    # Get the color palette
    colors = palette(palette_name, n_colors)
    
    # Create figure
    fig = Figure(resolution = (400, 300))
    
    # Create a simple matrix with discrete values 1 to n_colors
    data = reshape(1:n_colors, 1, n_colors)
    
    # Create heatmap
    ax = Axis(fig[1, 1])
    hm = heatmap!(ax, data, colormap = colors, colorrange = (1, n_colors))
    
    # Add discrete colorbar
    colorbar = Colorbar(fig[1, 2], hm, 
                       ticks = 1:n_colors,
                       label = palette_name,
                       vertical = true)
    
    # Hide axis elements since we just want the colorbar
    hidedecorations!(ax)
    
    display(fig)
end

export simple_colorbar
