using CairoMakie
using DataFrames
using CairoMakie: xlims!, ylims!

"""
    create_grid_of_labels(fig, grid_position, data_matrix; 
                         headers=nothing, 
                         cell_width=0.15, 
                         cell_height=0.08,
                         fontsize=12,
                         header_fontsize=14,
                         header_color=:black,
                         data_color=:black,
                         background_color=:white,
                         border_color=:gray)

Create a grid of labels to display tabular data instead of using Table.

# Arguments
- `fig`: The Figure object
- `grid_position`: The grid position (e.g., fig[1, 1])
- `data_matrix`: Matrix of data to display
- `headers`: Optional vector of header strings
- `cell_width`: Width of each cell (default: 0.15)
- `cell_height`: Height of each cell (default: 0.08)
- `fontsize`: Font size for data cells (default: 12)
- `header_fontsize`: Font size for headers (default: 14)
- `header_color`: Color for header text (default: :black)
- `data_color`: Color for data text (default: :black)
- `background_color`: Background color for cells (default: :white)
- `border_color`: Border color for cells (default: :gray)

# Returns
- Tuple of (min_x, max_x, min_y, max_y) for the grid bounds
"""
function create_grid_of_labels(fig, grid_position, data_matrix; 
                             headers=nothing, 
                             cell_width=0.15, 
                             cell_height=0.08,
                             fontsize=12,
                             header_fontsize=14,
                             header_color=:black,
                             data_color=:black,
                             background_color=:white,
                             border_color=:gray)
    
    # Normalize data_matrix to a 2D Matrix{String} with correct number of columns
    if !isnothing(headers)
        ncols_data = length(headers)
        if data_matrix isa Vector{Vector}
            nrows_data = length(data_matrix)
            norm_matrix = Matrix{String}(undef, nrows_data, ncols_data)
            for i in 1:nrows_data
                row = data_matrix[i]
                for j in 1:ncols_data
                    if j <= length(row)
                        norm_matrix[i, j] = string(row[j])
                    else
                        norm_matrix[i, j] = ""
                    end
                end
            end
        elseif data_matrix isa Vector
            nrows_data = 1
            norm_matrix = Matrix{String}(undef, 1, ncols_data)
            for j in 1:ncols_data
                if j <= length(data_matrix)
                    norm_matrix[1, j] = string(data_matrix[j])
                else
                    norm_matrix[1, j] = ""
                end
            end
        else
            nrows_data = size(data_matrix, 1)
            norm_matrix = Matrix{String}(undef, nrows_data, ncols_data)
            for i in 1:nrows_data
                for j in 1:ncols_data
                    if j <= size(data_matrix, 2)
                        norm_matrix[i, j] = string(data_matrix[i, j])
                    else
                        norm_matrix[i, j] = ""
                    end
                end
            end
        end
    else
        if data_matrix isa Vector{Vector}
            nrows_data = length(data_matrix)
            ncols_data = length(data_matrix[1])
            norm_matrix = Matrix{String}(undef, nrows_data, ncols_data)
            for i in 1:nrows_data
                for j in 1:ncols_data
                    norm_matrix[i, j] = string(data_matrix[i][j])
                end
            end
        elseif data_matrix isa Vector
            nrows_data = 1
            ncols_data = length(data_matrix)
            norm_matrix = Matrix{String}(undef, 1, ncols_data)
            for j in 1:ncols_data
                norm_matrix[1, j] = string(data_matrix[j])
            end
        else
            nrows_data, ncols_data = size(data_matrix)
            norm_matrix = Matrix{String}(undef, nrows_data, ncols_data)
            for i in 1:nrows_data
                for j in 1:ncols_data
                    norm_matrix[i, j] = string(data_matrix[i, j])
                end
            end
        end
    end

    # Now use norm_matrix for all further logic
    nrows = nrows_data
    ncols = ncols_data

    # Add header row if provided
    if !isnothing(headers)
        nrows += 1
        extended_matrix = Matrix{String}(undef, nrows, ncols)
        extended_matrix[1, :] = headers
        extended_matrix[2:end, :] = norm_matrix
        println("DEBUG: nrows=", nrows, ", ncols=", ncols, ", size(extended_matrix)=", size(extended_matrix))
    else
        extended_matrix = norm_matrix
        println("DEBUG: nrows=", nrows, ", ncols=", ncols, ", size(extended_matrix)=", size(extended_matrix))
    end
    
    # Calculate grid bounds
    grid_width = ncols * cell_width
    grid_height = nrows * cell_height
    
    # Center the grid in the available space
    min_x = -grid_width / 2
    max_x =  grid_width / 2
    min_y = -grid_height / 2
    max_y =  grid_height / 2
    
    # Create axis for the grid
    ax = Axis(grid_position,
              xgridvisible=false, ygridvisible=false,
              xticksvisible=false, yticksvisible=false,
              xticklabelsvisible=false, yticklabelsvisible=false)
    xlims!(ax, min_x - cell_width/2, max_x + cell_width/2)
    ylims!(ax, min_y - cell_height/2, max_y + cell_height/2)
    
    # Create grid of labels
    for row in 1:nrows
        for col in 1:ncols
            # Calculate cell position
            x = min_x + (col - 0.5) * cell_width
            y = max_y - (row - 0.5) * cell_height
            
            # Determine if this is a header row
            is_header = !isnothing(headers) && row == 1
            
            # Create background rectangle
            rect = Rect(x - cell_width/2, y - cell_height/2, cell_width, cell_height)
            poly!(ax, rect, color=background_color, strokecolor=border_color, strokewidth=1)
            
            # Create text label
            text_color = is_header ? header_color : data_color
            text_size = is_header ? header_fontsize : fontsize
            
            text!(ax, x, y, text=extended_matrix[row, col], 
                  color=text_color, fontsize=text_size, 
                  align=(:center, :center))
        end
    end
    
    return (min_x, max_x, min_y, max_y)
end

# Example usage
if abspath(PROGRAM_FILE) == @__FILE__
    # Create sample data
    data = [["3,126", "157", "1,126", "1,843"]]
    headers = ["Total Counties", "Trauma Centers", "Nearby Counties", "Other Counties"]
    
    # Create figure
    fig = Figure(size=(800, 400))
    
    # Create grid of labels
    bounds = create_grid_of_labels(fig, fig[1, 1], data, 
                                  headers=headers,
                                  cell_width=0.2,
                                  cell_height=0.1,
                                  fontsize=14,
                                  header_fontsize=16)
    
    # Add a title
    Label(fig[0, 1], "Trauma Center Statistics", fontsize=20)
    
    display(fig)
    
    println("Grid of labels created successfully!")
    println("This replaces the Table function with a custom grid layout.")
end

# Export the function
export create_grid_of_labels 