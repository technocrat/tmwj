using CairoMakie
using StatsBase 


"""
    quick_hist(v::Vector{T}, xlab::String, ylab::String, title::String) where T <: Real

Create a histogram plot with customizable labels and title.

# Arguments
- `v::Vector{T}`: Vector of numeric data to create histogram from
- `xlab::String`: Label for the x-axis
- `ylab::String`: Label for the y-axis  
- `title::String`: Title for the plot

# Returns
- `fig::Figure`: Makie figure object containing the histogram

# Examples
```julia
data = randn(1000)
fig = quick_hist(data, "Values", "Frequency", "Normal Distribution")
save("histogram.pdf", fig)
```

# Notes
- Automatically handles missing values by skipping them
- Uses 30 bins by default
- Colors bars blue for negative values and red for non-negative values
- Returns a figure object that can be saved to various formats
"""
function quick_hist(v::Vector{T}, xlab::String, ylab::String, title::String) where T <: Real
    data    = collect(skipmissing(v))
    h       = fit(Histogram, data; nbins = 30)
    edges   = h.edges[1]                       # length = nbins+1
    counts  = h.weights                        # length = nbins
    centers = (edges[1:end-1] .+ edges[2:end]) ./ 2
    
    # blue for negative‐center bins, red for non‐negative
    bar_colors = ifelse.(centers .< 0, :blue, :red)
    
    fig = Figure(size = (800, 600), fontsize = 24)
    ax  = Axis(fig[1, 1];
    xlabel = xlab,
    ylabel = ylab,
    title  = title,
    )
    
    barplot!(ax, centers, counts;
    width       = diff(edges),
    color       = bar_colors,
    strokecolor = :black,
    strokewidth = 1,
    )
        
    return fig
end

export quick_hist