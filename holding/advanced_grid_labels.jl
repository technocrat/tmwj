using CairoMakie
using DataFrames

"""
    create_advanced_grid_labels(fig, grid_position, data; 
                               headers=nothing,
                               row_labels=nothing,
                               cell_padding=0.02,
                               fontsize=12,
                               header_fontsize=14,
                               row_label_fontsize=12,
                               header_color=:black,
                               data_color=:black,
                               row_label_color=:black,
                               background_color=:white,
                               header_background=:lightgray,
                               border_color=:gray,
                               border_width=1.0,
                               text_align=(:center, :center))

Create an advanced grid of labels for displaying tabular data with multiple formatting options.

# Arguments
- `fig`: The Figure object
- `grid_position`: The grid position (e.g., fig[1, 1])
- `data`: Matrix or Vector of Vectors containing the data
- `headers`: Optional vector of header strings
- `row_labels`: Optional vector of row label strings
- `cell_padding`: Padding around text in cells (default: 0.02)
- `fontsize`: Font size for data cells (default: 12)
- `header_fontsize`: Font size for headers (default: 14)
- `row_label_fontsize`: Font size for row labels (default: 12)
- `header_color`: Color for header text (default: :black)
- `data_color`: Color for data text (default: :black)
- `row_label_color`: Color for row label text (default: :black)
- `background_color`: Background color for data cells (default: :white)
- `header_background`: Background color for header cells (default: :lightgray)
- `border_color`: Border color for cells (default: :gray)
- `border_width`: Border width (default: 1.0)
- `text_align`: Text alignment tuple (default: (:center, :center))

# Returns
- Tuple of (min_x, max_x, min_y, max_y) for the grid bounds
"""
function create_advanced_grid_labels(fig, grid_position, data; 
                                   headers=nothing,
                                   row_labels=nothing,
                                   cell_padding=0.02,
                                   fontsize=12,
                                   header_fontsize=14,
                                   row_label_fontsize=12,
                                   header_color=:black,
                                   data_color=:black,
                                   row_label_color=:black,
                                   background_color=:white,
                                   header_background=:lightgray,
                                   border_color=:gray,
                                   border_width=1.0,
                                   text_align=(:center, :center))
    
    # Convert data to matrix if it's a vector of vectors
    if data isa Vector{Vector}
        data_matrix = Matrix{String}(undef, length(data), length(data[1]))
        for (i, row) in enumerate(data)
            for (j, val) in enumerate(row)
                data_matrix[i, j] = string(val)
            end
        end
    else
        data_matrix = string.(data)
    end
    
    # Get dimensions
    nrows, ncols = size(data_matrix)
    
    # Calculate total dimensions including headers and row labels
    total_rows = nrows
    total_cols = ncols
    
    if !isnothing(headers)
        total_rows += 1
    end
    
    if !isnothing(row_labels)
        total_cols += 1
    end
    
    # Create extended matrix
    extended_matrix = Matrix{String}(undef, total_rows, total_cols)
    
    # Fill in the data
    data_start_row = isnothing(headers) ? 1 : 2
    data_start_col = isnothing(row_labels) ? 1 : 2
    
    extended_matrix[data_start_row:end, data_start_col:end] = data_matrix
    
    # Add headers if provided
    if !isnothing(headers)
        extended_matrix[1, data_start_col:end] = headers
    end
    
    # Add row labels if provided
    if !isnothing(row_labels)
        extended_matrix[data_start_row:end, 1] = row_labels
    end
    
    # Calculate cell dimensions based on content
    cell_widths = zeros(total_cols)
    cell_heights = zeros(total_rows)
    
    # Estimate cell widths based on text length
    for col in 1:total_cols
        max_width = 0
        for row in 1:total_rows
            text_width = length(extended_matrix[row, col]) * 0.08  # Rough estimate
            max_width = max(max_width, text_width)
        end
        cell_widths[col] = max_width + 2 * cell_padding
    end
    
    # Set cell heights
    for row in 1:total_rows
        cell_heights[row] = 0.1  # Fixed height for now
    end
    
    # Calculate grid bounds
    grid_width = sum(cell_widths)
    grid_height = sum(cell_heights)
    
    # Center the grid
    min_x = -grid_width / 2
    max_x = grid_width / 2
    min_y = -grid_height / 2
    max_y = grid_height / 2
    
    # Create axis for the grid
    ax = Axis(grid_position, 
              xlims=(min_x - cell_padding, max_x + cell_padding),
              ylims=(min_y - cell_padding, max_y + cell_padding),
              aspect=DataAspect(),
              xgridvisible=false, ygridvisible=false,
              xticksvisible=false, yticksvisible=false,
              xticklabelsvisible=false, yticklabelsvisible=false)
    
    # Create grid of labels
    current_x = min_x
    for col in 1:total_cols
        current_y = max_y
        
        for row in 1:total_rows
            # Determine cell properties
            is_header = !isnothing(headers) && row == 1
            is_row_label = !isnothing(row_labels) && col == 1
            
            # Set colors and font sizes
            if is_header
                bg_color = header_background
                text_color = header_color
                text_size = header_fontsize
            elseif is_row_label
                bg_color = background_color
                text_color = row_label_color
                text_size = row_label_fontsize
            else
                bg_color = background_color
                text_color = data_color
                text_size = fontsize
            end
            
            # Create background rectangle
            rect = Rect(current_x, current_y - cell_heights[row], 
                       cell_widths[col], cell_heights[row])
            poly!(ax, rect, color=bg_color, strokecolor=border_color, 
                  strokewidth=border_width)
            
            # Create text label
            text_x = current_x + cell_widths[col] / 2
            text_y = current_y - cell_heights[row] / 2
            
            text!(ax, text_x, text_y, text=extended_matrix[row, col], 
                  color=text_color, fontsize=text_size, 
                  align=text_align)
            
            current_y -= cell_heights[row]
        end
        
        current_x += cell_widths[col]
    end
    
    return (min_x, max_x, min_y, max_y)
end

# Example usage with trauma center data
if abspath(PROGRAM_FILE) == @__FILE__
    # Create sample trauma center data
    trauma_data = [
        ["3,126", "157", "1,126", "1,843"],
        ["85.2%", "5.0%", "36.0%", "59.0%"]
    ]
    
    headers = ["Total Counties", "Trauma Centers", "Nearby Counties", "Other Counties"]
    row_labels = ["Count", "Percentage"]
    
    # Create figure
    fig = Figure(size=(1000, 500))
    
    # Create advanced grid of labels
    bounds = create_advanced_grid_labels(fig, fig[1, 1], trauma_data, 
                                        headers=headers,
                                        row_labels=row_labels,
                                        cell_padding=0.03,
                                        fontsize=14,
                                        header_fontsize=16,
                                        row_label_fontsize=14,
                                        header_background=:lightblue,
                                        border_color=:darkgray,
                                        border_width=1.5)
    
    # Add a title
    Label(fig[0, 1], "US Trauma Center Coverage Statistics", fontsize=24)
    
    # Add a subtitle
    Label(fig[2, 1], "Data shows county coverage by Level 1 trauma centers within 50 miles", 
          fontsize=12, color=:gray)
    
    display(fig)
    
    println("Advanced grid of labels created successfully!")
    println("This provides a flexible alternative to the Table function.")
end

# Export the function
export create_advanced_grid_labels 