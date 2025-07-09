using CairoMakie
using ColorSchemes

"""
    continuous_colorbar(colormap=:viridis; label=nothing, size=(400, 300))
Display a heatmap with a continuous colorbar using the specified colormap.
- `colormap`: Can be a ColorSchemes symbol (e.g., :viridis) or a custom vector of colors.
"""
function continuous_colorbar(colormap=:viridis; label=nothing, size=(400, 300))
    # Set default label based on colormap
    if label === nothing
        if typeof(colormap) <: Symbol
            label = string(colormap)
        else
            label = "custom"
        end
    end
    # Prepend 'Continuous: ' to label if not already present
    if !occursin(r"continuous"i, label)
        label = "Continuous: " * label
    end
    fig = Figure(size = size)
    ax = Axis(fig[1, 1], title = "Map Colors",
        xticksvisible = false,
        yticksvisible = false,
        xticklabelsvisible = false,
        yticklabelsvisible = false)

    # Get the colors from the colormap
    if typeof(colormap) <: Symbol
        colors = get(ColorSchemes.colorschemes, colormap, ColorSchemes.viridis)
        if typeof(colors) <: Symbol
            colors = ColorSchemes.colorschemes[colors]
        end
    else
        colors = colormap
    end

    data = rand(10, 10)
    hm = heatmap!(ax, data, colormap=colors)
    Colorbar(fig[1, 2], hm, label=label,
        ticksvisible = false,
        ticklabelsvisible = false)
    display(fig)
    return fig
end

"""
    discrete_colorbar(colormap=:Blues_9; label=nothing, size=(400, 300))
Display a heatmap with a discrete colorbar using the specified colormap.
- `colormap`: Can be a ColorSchemes symbol (e.g., :Blues_9) or a custom vector of colors.
"""
function discrete_colorbar(colormap=:Blues_9; label=nothing, size=(400, 300))
    # Set default label based on colormap
    if label === nothing
        if typeof(colormap) <: Symbol
            label = string(colormap)
        else
            label = "custom"
        end
    end
    # Prepend 'Discrete: ' to label if not already present
    if !occursin(r"discrete"i, label)
        label = "Discrete: " * label
    end
    fig = Figure(size = size)
    ax = Axis(fig[1, 1], title = "Map Colors",
        xticksvisible = false,
        yticksvisible = false,
        xticklabelsvisible = false,
        yticklabelsvisible = false)

    # Get the colors from the colormap
    if typeof(colormap) <: Symbol
        colors = get(ColorSchemes.colorschemes, colormap, ColorSchemes.Blues_9)
        if typeof(colors) <: Symbol
            colors = ColorSchemes.colorschemes[colors]
        end
    else
        colors = colormap
    end
    n_colors = length(colors)

    data = rand(1:n_colors, 10, 10)
    hm = heatmap!(ax, data, colormap=colors)

    # Place the colorbar in a new row below the heatmap
    cb_ax = Axis(fig[2, 1],
        xticksvisible = false, yticksvisible = false,
        xticklabelsvisible = false, yticklabelsvisible = false,
        leftspinevisible = false, rightspinevisible = false,
        topspinevisible = false, bottomspinevisible = false,
        backgroundcolor = :transparent, height=40)
    hidespines!(cb_ax)
    hidedecorations!(cb_ax)
    
    # Draw horizontal color boxes
    bar_width = 1.0 / n_colors
    for i in 1:n_colors
        x_center = (i - 0.5) * bar_width
        y_center = 0.5
        x_min = x_center - bar_width / 2
        x_max = x_center + bar_width / 2
        y_min = 0.0
        y_max = 1.0
        rect = [Point2f(x_min, y_min), Point2f(x_max, y_min),
                Point2f(x_max, y_max), Point2f(x_min, y_max)]
        poly!(cb_ax, rect, color=colors[i])
    end
    xlims!(cb_ax, 0, 1)
    ylims!(cb_ax, 0, 1)
    
    # Add label in a new row below the colorbar
    Label(fig[3, 1], label, halign = :center, valign = :top, fontsize=18)
    display(fig)
    return fig
end

# Example usage:
println("Testing continuous colorbar:")
continuous_colorbar(:viridis)

println("\nTesting discrete colorbar:")
discrete_colorbar(:Blues_9)

println("\nTesting custom discrete colorbar:")
custom_colors = [:red, :orange, :yellow, :green, :blue, :purple]
discrete_colorbar(custom_colors)

println("\nTesting continuous with Set2_3:")
continuous_colorbar(:Set2_3)

println("\nTesting discrete with Set2_3:")
discrete_colorbar(:Set2_3)