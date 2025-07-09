using CommonMark
using GeoMakie
using GeometryBasics
using Humanize

# include("src/scalebar_drop_in.jl")

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

function markdown_table_to_text(markdown_string::String)
    # Parse the markdown
    parser = Parser()
    parsed = parser(markdown_string)
    
    # Convert to terminal output (plain text with some formatting)
    return term(parsed)
end



# Function to create a scalebar
function add_scalebar!(ax, x_pos, y_pos, length, map_width_degrees, map_width_km; unit=:km)
    # Convert to km if unit is miles
    length_km = unit == :miles ? length * 1.60934 : length
    
    # Calculate the length in map coordinates
    length_degrees = length_km * (map_width_degrees / map_width_km)
    
    # Scalebar line
    lines!(ax, [x_pos, x_pos + length_degrees], [y_pos, y_pos], 
           color = :black, linewidth = 3)
    
    # Scalebar end markers
    lines!(ax, [x_pos, x_pos], [y_pos - 0.1, y_pos + 0.1], 
           color = :black, linewidth = 2)
    lines!(ax, [x_pos + length_degrees, x_pos + length_degrees], 
           [y_pos - 0.1, y_pos + 0.1], color = :black, linewidth = 2)
    
    # Scalebar text
    unit_text = unit == :miles ? "mi" : "km"
    text!(ax, x_pos + length_degrees/2, y_pos + 0.3, 
          text = "$(length) $(unit_text)", align = (:center, :bottom),
          fontsize = 12, color = :black)
end

# Function to create a north arrow
function add_north_arrow!(ax, x_pos, y_pos, size = 1.0)
    # Arrow shaft
    lines!(ax, [x_pos, x_pos], [y_pos, y_pos + size], 
           color = :black, linewidth = 2)
    
    # Arrow head (triangle)
    arrow_head = [Point2f(x_pos, y_pos + size),
                  Point2f(x_pos - 0.2*size, y_pos + 0.7*size),
                  Point2f(x_pos + 0.2*size, y_pos + 0.7*size)]
    
    poly!(ax, arrow_head, color = :black)
    
    # "N" label
    text!(ax, x_pos, y_pos + size + 0.3, text = "N", 
          align = (:center, :bottom), fontsize = 14, 
          font = :bold, color = :black)
end

# More sophisticated north arrow with white fill and black outline
function add_fancy_north_arrow!(ax, x_pos, y_pos, size = 1.0)
    # Arrow shaft
    lines!(ax, [x_pos, x_pos], [y_pos, y_pos + size], 
           color = :black, linewidth = 3)
    
    # Arrow head with white fill and black outline
    arrow_head = [Point2f(x_pos, y_pos + size),
                  Point2f(x_pos - 0.25*size, y_pos + 0.6*size),
                  Point2f(x_pos + 0.25*size, y_pos + 0.6*size)]
    
    poly!(ax, arrow_head, color = :white, strokecolor = :black, strokewidth = 2)
    
    # "N" label with background
    text!(ax, x_pos, y_pos + size + 0.4, text = "N", 
          align = (:center, :bottom), fontsize = 16, 
          font = :bold, color = :black)
end

# Example usage with a simple map
function create_map_with_elements()
    fig = Figure(size = (800, 600))
    
    # Create a GeoAxis for mapping
    ax = GeoAxis(fig[1, 1], 
                 dest = "+proj=merc +datum=WGS84")
    
    # Set the limits after creating the axis
    xlims!(ax, -10, 10)
    ylims!(ax, 40, 60)
    
    # Add some sample data (coastlines would go here in real usage)
    # For demonstration, just add some points
    lons = [-5, 0, 5]
    lats = [45, 50, 55]
    scatter!(ax, lons, lats, color = :red, markersize = 15)
    
    # Add scalebar (bottom left) - kilometers
    add_scalebar!(ax, -9, 41, 500, 20, 1400, unit=:km)  # 500km scalebar
    
    # Add scalebar (bottom right) - miles
    add_scalebar!(ax, 5, 41, 300, 20, 1400, unit=:miles)  # 300mi scalebar
    
    # Add north arrow (top right)
    add_fancy_north_arrow!(ax, 8, 57, 1.5)
    
    return fig
end

# Alternative scalebar with background box and alternating segments
function add_scalebar_with_box!(ax, x_pos, y_pos, length, map_width_degrees, map_width_km; unit=:km)
    # Convert to km if unit is miles
    length_km = unit == :miles ? length * 1.60934 : length
    
    length_degrees = length_km * (map_width_degrees / map_width_km)
    
    # Define break points for alternating segments
    break_points = [50, 100, 250, 500, 1000, 2000, 3000]
    
    # Find the appropriate break point for this length
    target_break = 0
    for bp in break_points
        if length <= bp
            target_break = bp
            break
        end
    end
    
    # If length is larger than all break points, use the largest
    if target_break == 0
        target_break = break_points[end]
    end
    
    # Convert break point to map coordinates
    target_break_km = unit == :miles ? target_break * 1.60934 : target_break
    target_break_degrees = target_break_km * (map_width_degrees / map_width_km)
    
    # Tight background box (no gap)
    box_left   = x_pos
    box_right  = x_pos + target_break_degrees
    box_bottom = y_pos - 0.18   # Just below the bottom rule
    box_top    = y_pos + 0.18   # Just above the top rule
    box_points = [
        Point2f(box_left,  box_bottom),
        Point2f(box_right, box_bottom),
        Point2f(box_right, box_top),
        Point2f(box_left,  box_top)
    ]
    poly!(ax, box_points, color = (:white, 0.8), strokecolor = :black, strokewidth = 1)
    
    # Create alternating black/white segments
    n_segments = 4  # Number of segments to show
    segment_length = target_break_degrees / n_segments
    
    # Add top and bottom rules to enclose the scalebar
    lines!(ax, [x_pos, x_pos + target_break_degrees], [y_pos + 0.15, y_pos + 0.15], 
           color = :black, linewidth = 1)  # Top rule
    lines!(ax, [x_pos, x_pos + target_break_degrees], [y_pos - 0.15, y_pos - 0.15], 
           color = :black, linewidth = 1)  # Bottom rule
    
    for i in 0:(n_segments-1)
        color = i % 2 == 0 ? :black : :white
        lines!(ax, [x_pos + i*segment_length, x_pos + (i+1)*segment_length], 
               [y_pos, y_pos], color = color, linewidth = 6)
    end
    
    # Labels
    unit_text = unit == :miles ? "mi" : "km"
    text!(ax, x_pos, y_pos - 0.2, text = "0", align = (:center, :top), fontsize = 10)
    text!(ax, x_pos + target_break_degrees/2, y_pos - 0.2, text = "$(target_break÷2)", 
          align = (:center, :top), fontsize = 10)
    text!(ax, x_pos + target_break_degrees, y_pos - 0.2, text = "$(target_break) $(unit_text)", 
          align = (:center, :top), fontsize = 10)
end

# Function to calculate appropriate scalebar length based on map extent
function calculate_scalebar_length(map_width_km; unit=:km)
    # Choose a "nice" length that's roughly 1/4 to 1/3 of map width
    target_length = map_width_km / 4
    
    # Use the predefined break points
    break_points = [50, 100, 250, 500, 1000, 2000, 3000]
    
    # Convert target_length to the same unit as break_points
    if unit == :miles
        target_length = target_length / 1.60934
    end
    
    # Find the closest break point
    closest_idx = argmin(abs.(break_points .- target_length))
    return break_points[closest_idx]
end

# Example with automatic scalebar sizing
function create_auto_scaled_map()
    fig = Figure(size = (800, 600))
    
    ax = GeoAxis(fig[1, 1], 
                 dest = "+proj=merc +datum=WGS84")
    
    # Set the limits after creating the axis
    xlims!(ax, -2, 2)
    ylims!(ax, 51, 53)
    
    # Calculate map dimensions (approximate for this projection)
    map_width_degrees = 4
    map_width_km = 280  # Approximate width in km at this latitude
    
    # Auto-calculate scalebar length (kilometers)
    scalebar_length_km = calculate_scalebar_length(map_width_km, unit=:km)
    
    # Auto-calculate scalebar length (miles)
    scalebar_length_mi = calculate_scalebar_length(map_width_km, unit=:miles)
    
    # Add elements
    add_scalebar_with_box!(ax, -1.8, 51.2, scalebar_length_km, map_width_degrees, map_width_km, unit=:km)
    add_scalebar_with_box!(ax, 0.5, 51.2, scalebar_length_mi, map_width_degrees, map_width_km, unit=:miles)
    add_fancy_north_arrow!(ax, 1.6, 52.7, 0.15)
    
    return fig
end


function autolims!(ax, xs, ys; margin=0.05)
    xmin, xmax = extrema(xs)
    ymin, ymax = extrema(ys)
    xrange = xmax - xmin
    yrange = ymax - ymin
    xlims!(ax, xmin - margin*xrange, xmax + margin*xrange)
    ylims!(ax, ymin - margin*yrange, ymax + margin*yrange)
end