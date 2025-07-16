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

# Simple function to transform Hawaii to lat/lon coordinates for inset placement
function transform_hawaii_to_latlon(hawaii_geoms, scale=0.3, offset_lon=-115.0, offset_lat=25.0)
    transformed_geoms = map(hawaii_geoms) do geom
        try
            coords = GeoInterface.coordinates(geom)
            
            # Handle both Polygon and MultiPolygon
            if ArchGDAL.getgeomtype(geom) == ArchGDAL.wkbMultiPolygon
                exterior_ring = coords[1][1]
            else
                exterior_ring = coords[1]
            end
            
            # Transform coordinates
            new_coords = map(exterior_ring) do coord_pair
                lon, lat = coord_pair[1], coord_pair[2]
                
                # Center Hawaii around its approximate center
                centered_lon = lon - (-156.0)  # Hawaii center longitude
                centered_lat = lat - 19.5      # Hawaii center latitude
                
                # Scale and place in new location
                new_lon = centered_lon * scale + offset_lon
                new_lat = centered_lat * scale + offset_lat
                
                [new_lon, new_lat]
            end
            
            # Create new geometry
            coord_string = join(["$(coord[1]) $(coord[2])" for coord in new_coords], ", ")
            new_wkt = "POLYGON(($coord_string))"
            ArchGDAL.fromWKT(new_wkt)
            
        catch e
            println("Error transforming Hawaii geometry: ", e)
            geom  # Return original on error
        end
    end
    
    return transformed_geoms
end

# Function to transform Alaska to lat/lon coordinates for inset placement
function transform_alaska_to_latlon(alaska_geoms, scale=0.25, offset_lon=-115.0, offset_lat=35.0)
    transformed_geoms = map(alaska_geoms) do geom
        try
            coords = GeoInterface.coordinates(geom)
            
            # Handle both Polygon and MultiPolygon
            if ArchGDAL.getgeomtype(geom) == ArchGDAL.wkbMultiPolygon
                exterior_ring = coords[1][1]
            else
                exterior_ring = coords[1]
            end
            
            # Transform coordinates
            new_coords = map(exterior_ring) do coord_pair
                lon, lat = coord_pair[1], coord_pair[2]
                
                # Center Alaska around its approximate center
                centered_lon = lon - (-154.0)  # Alaska center longitude (approximate)
                centered_lat = lat - 64.0      # Alaska center latitude (approximate)
                
                # Scale and place in new location
                new_lon = centered_lon * scale + offset_lon
                new_lat = centered_lat * scale + offset_lat
                
                [new_lon, new_lat]
            end
            
            # Create new geometry
            coord_string = join(["$(coord[1]) $(coord[2])" for coord in new_coords], ", ")
            new_wkt = "POLYGON(($coord_string))"
            ArchGDAL.fromWKT(new_wkt)
            
        catch e
            println("Error transforming Alaska geometry: ", e)
            geom  # Return original on error
        end
    end
    
    return transformed_geoms
end

function check_alaska_range(geoms)
    all_coords = []
    for geom in geoms[1:min(10, length(geoms))]
        try
            coords = GeoInterface.coordinates(geom)[1]
            append!(all_coords, coords)
        catch
            continue
        end
    end
    
    if !isempty(all_coords)
        x_coords = [c[1] for c in all_coords]
        y_coords = [c[2] for c in all_coords]
        println("Alaska inset X range: ", extrema(x_coords))
        println("Alaska inset Y range: ", extrema(y_coords))
    end
end

check_alaska_range(alaska.geometry)