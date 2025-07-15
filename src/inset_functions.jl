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

function inset_state(state::GeoTable{<:GeometrySet}, rotation::Number, scale::Number, x_offset::Number, y_offset::Number, direction::String = "ccw")
    θ = direction == "ccw" ? π/rotation : -π/rotation
    R = Angle2d(θ)
    S = Diagonal(SVector(scale, scale))
    A = S * R
    # increasing x moves the geometry to the right and increasing y lowers the geometry
    b = SVector(x_offset, y_offset)
    af = Affine(A, b)
    transformed_geometry = af.(state.geometry)
    return GeoTable(GeometrySet(transformed_geometry), vtable=state)
end

function get_counties(shape_file::String)
    ak_crs = CoordRefSystems.EPSG{3338}
    projector_ak = Proj(ak_crs)
    hi_crs = CoordRefSystems.shift(Albers{13, 8, 18, NAD83}, lonₒ=-157)
    projector_hi = Proj(hi_crs)
    data = DataFrame(GeoIO.load(shape_file))
    alaska = GeoTable(data[data.STUSPS .== "AK", :]) |> projector_ak  
    hawaii = GeoTable(data[data.STUSPS .== "HI", :]) |> projector_hi
    alaska = DataFrame(alaska)
    hawaii = DataFrame(hawaii)
    return alaska, hawaii
end