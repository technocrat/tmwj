using CommonMark
using GeoMakie
using GeometryBasics
using Humanize
using CairoMakie
using StatsBase
using ColorSchemes 



function with_commas(x)
    x = Int64.(x)
    return Humanize.digitsep.(x)
end

function percent(x::Float64)
    x = Float64(x)
    return string(round(x * 100; digits=2)) * "%"
end 

function hard_wrap(text::String, width::Int)
    """
    Hard-wrap text at the specified width, breaking at word boundaries when possible.
    Each line is right-padded to the specified width.
    
    Args:
        text: The text to wrap
        width: Maximum line width in characters
    
    Returns:
        String with line breaks inserted and each line padded to width
    """
    if width <= 0
        return text
    end
    
    words = split(text, " ")
    lines = String[]
    current_line = ""
    
    for word in words
        # If adding this word would exceed the width
        if length(current_line) + length(word) + 1 > width
            # If current line is not empty, start a new line
            if !isempty(current_line)
                push!(lines, rpad(current_line, width))
                current_line = word
            else
                # Current line is empty, so the word itself is too long
                # Break the word if it exceeds width
                if length(word) > width
                    # Break the word at the width limit
                    push!(lines, rpad(word[1:width], width))
                    current_line = word[width+1:end]
                else
                    current_line = word
                end
            end
        else
            # Add word to current line
            if isempty(current_line)
                current_line = word
            else
                current_line *= " " * word
            end
        end
    end
    
    # Add the last line if it's not empty
    if !isempty(current_line)
        push!(lines, rpad(current_line, width))
    end
    
    return join(lines, "\n")
end


function format_table_as_text(headers::Vector{String}, rows::Vector{Vector{String}}, 
    padding::Int=2)
    parser = Parser()
    all_rows = [headers; rows]

    # Calculate column widths
    col_widths = Int[]
    for col in 1:length(headers)
    max_width = maximum(length(row[col]) for row in all_rows)
    push!(col_widths, max_width + padding)
    end

    # Format rows
    formatted_lines = String[]

    # Header
    header_line = join([rpad(headers[i], col_widths[i]) for i in 1:length(headers)], "│")
    push!(formatted_lines, "│" * header_line * "│")

    # Separator
    separator = "├" * join([repeat("─", col_widths[i]) for i in 1:length(headers)], "┼") * "┤"
    push!(formatted_lines, separator)

    # Data rows
    for row in rows
    data_line = join([rpad(row[i], col_widths[i]) for i in 1:length(row)], "│")
    push!(formatted_lines, "│" * data_line * "│")
    end

    # Top and bottom borders
    top_border = "┌" * join([repeat("─", col_widths[i]) for i in 1:length(headers)], "┬") * "┐"
    bottom_border = "└" * join([repeat("─", col_widths[i]) for i in 1:length(headers)], "┴") * "┘"

    return join([top_border, formatted_lines..., bottom_border], "\n")
end




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

"""
    split_string_into_n_parts(text::String, n::Int)

Split a string into n approximately equal parts, inserting newlines at word boundaries.

# Arguments
- `text::String`: The text string to split
- `n::Int`: Number of parts to split the string into

# Returns
- `String`: The original text with newlines inserted to create n parts

# Examples
```julia
text = "This is a long text that needs to be split into multiple parts for better formatting."
result = split_string_into_n_parts(text, 3)
# Returns text split into 3 parts with newlines at word boundaries
```

# Notes
- Attempts to break at word boundaries when possible
- If a word is longer than the target part length, it will be broken mid-word
- Each part will be approximately equal in length
- Preserves original spacing between words
"""
function split_string_into_n_parts(text::String, n::Int)
    if n <= 1
        return text
    end
    
    # Calculate target length for each part
    total_length = length(text)
    target_length = div(total_length, n)
    
    # Split into characters
    chars = split(text, "")
    
    # Initialize result
    result = String[]
    current_part = ""
    current_length = 0
    parts_created = 0
    
    for (i, char) in enumerate(chars)
        # Check if adding this character would exceed target length
        if !isempty(current_part) && current_length + 1 > target_length && parts_created < n - 1
            # Start a new part
            push!(result, current_part)
            current_part = char
            current_length = 1
            parts_created += 1
        else
            # Add character to current part
            current_part *= char
            current_length += 1
        end
    end
    
    # Add the last part
    if !isempty(current_part)
        push!(result, current_part)
    end
    
    # Join with newlines
    return join(result, "\n")
end

function dots(df::DataFrame, dots::Int)
    bu = df.wheat2017bu
    Int.(floor.(bu ./ dots))
end

"""
    plot_colorscheme(scheme_name::Symbol; n_colors::Int=256, figsize::Tuple{Int,Int}=(800, 200))

Display a colorscheme as horizontal color bar plots showing both discrete and continuous versions.

# Arguments
- `scheme_name::Symbol`: Name of the colorscheme (e.g., :viridis, :plasma, :RdYlBu, :Paired_9)
- `n_colors::Int`: Number of color samples to display for continuous version (default: 256)
- `figsize::Tuple{Int,Int}`: Figure size as (width, height) in pixels (default: (800, 400))

# Returns
- `fig::Figure`: Makie figure object containing both discrete and continuous visualizations

# Examples
```julia
# Display both discrete and continuous versions
fig = plot_colorscheme(:viridis)
display(fig)

# Display with custom parameters
fig = plot_colorscheme(:plasma, n_colors=128, figsize=(800, 300))
save("plasma_colorscheme.pdf", fig)

# Display a categorical colorscheme
fig = plot_colorscheme(:Paired_9)
display(fig)
```

# Notes
- Uses ColorSchemes.jl to access the colorscheme
- Shows discrete version first (numbered color blocks)
- Shows continuous version second (smooth gradient)
- For colorschemes with few colors, both versions may look similar
- The plot includes the colorscheme name as the title
- Returns a figure object that can be saved to various formats
"""
function plot_colorscheme(scheme_name::Symbol; n_colors::Int=256, figsize::Tuple{Int,Int}=(800, 400))
    # Get the colorscheme
    scheme = colorschemes[scheme_name]
    
    # Get discrete colors (all available colors)
    discrete_colors = collect(scheme)
    n_discrete = length(discrete_colors)
    
    # Create continuous colors
    x = range(0, 1, length=n_colors)
    continuous_colors = [scheme[i] for i in x]
    
    # Create figure with two rows
    fig = Figure(size=figsize, fontsize=16)
    
    # Discrete version (top row)
    ax_discrete = Axis(fig[1, 1],
        xlabel="Color Index",
        title=string(scheme_name) * " - Discrete"
    )
    hidedecorations!(ax_discrete, grid=false, label=false)
    
    # Show x-axis ticks for discrete version
    ax_discrete.xlabelvisible = true
    
    # Create discrete color blocks
    for (i, color) in enumerate(discrete_colors)
        poly!(ax_discrete, 
            Rect(i-1, 0, 1, 1), 
            color=color, 
            strokecolor=:black, 
            strokewidth=1.0
        )
        
        # Add text label for each color block
        text!(ax_discrete, 
            i-0.5, 0.5, 
            text=string(i), 
            align=(:center, :center),
            color=:black,
            fontsize=12
        )
    end
    xlims!(ax_discrete, 0, n_discrete)
    
    # Hide x-axis ticks since we have text labels
    ax_discrete.xticks = (Float64[], String[])
    
    # Continuous version (bottom row)
    ax_continuous = Axis(fig[2, 1],
        xlabel="Position",
        title=string(scheme_name) * " - Continuous"
    )
    hidedecorations!(ax_continuous, grid=false, label=false)
    
    # Hide x-axis ticks for continuous version (smooth gradient)
    ax_continuous.xticks = (Float64[], String[])
    
    # Create continuous color bar
    for (i, color) in enumerate(continuous_colors)
        poly!(ax_continuous, 
            Rect(i-1, 0, 1, 1), 
            color=color, 
            strokecolor=:black, 
            strokewidth=0.5
        )
    end
    xlims!(ax_continuous, 0, n_colors)
    
    return fig
end
