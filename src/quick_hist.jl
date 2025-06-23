using CairoMakie
using StatsBase  # for fit(Histogram)

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
        
    display(fig)
end

export quick_hist