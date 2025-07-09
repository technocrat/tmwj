using Unitful                      # for u"km"
using CairoMakie, GeoMakie
using GeometryBasics: Vec2f, Point3f

function geoscalebar!(
    ax::GeoAxis,
    scale::Quantity;
    muls        = [50,100,250,500,1000],
    target_frac = 0.2,
    position    = Vec2f(0.85, 0.08),
    color       = :black,
    linewidth   = 2,
)
    # Get the data limits directly (they're tuples)
    xlims, ylims = ax.limits[]
    
    # Calculate the width in data coordinates (longitude degrees)
    width_data = xlims[2] - xlims[1]
    
    # Convert scale to approximate degrees (1 degree ≈ 111 km at equator)
    scale_km = ustrip(scale)
    scale_degrees = scale_km / 111.0  # rough conversion
    
    # Find best multiple for target fraction of axis width
    target_width = target_frac * width_data
    diffs = abs.((muls .* scale_degrees) .- target_width)
    mul = muls[argmin(diffs)]
    
    # Calculate actual bar width in degrees
    bar_width = mul * scale_degrees
    
    # Convert relative position to data coordinates
    x_center = xlims[1] + position[1] * width_data
    y_pos = ylims[1] + position[2] * (ylims[2] - ylims[1])
    
    # Calculate bar endpoints
    x1 = x_center - bar_width/2
    x2 = x_center + bar_width/2
    
    # Draw the scalebar
    lines!(ax, [x1, x2], [y_pos, y_pos];
           color = color,
           linewidth = linewidth)
    
    # Add label
    text!(ax, "$(mul) $(unit(scale))";
          position = (x_center, y_pos),
          color = color,
          align = (:center, :bottom),
          offset = (0, 5))
    
    return nothing
end