"""
    divide_into_n_parts(v::Vector{<:Real}, n::Int)

Divide a vector into n+1 equal-width intervals and return the break points.

# Arguments
- `v::Vector{<:Real}`: Vector of numeric values to divide
- `n::Int`: Number of break points (creates n+1 equal-width intervals)

# Returns
- `Vector{Float64}`: Break points that divide the vector into n+1 equal-width intervals

# Examples
```julia
data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
breaks = divide_into_n_parts(data, 4)  # Returns [7.75, 5.5, 3.25, 1.0]
# This creates 5 equal-width bins: [7.75-10], [5.5-7.75), [3.25-5.5), [1-3.25), [0-1)

# For population data
breaks = divide_into_n_parts(conus.Population, 5)  # 5 break points, 6 bins
```

# Notes
- Uses equal-width intervals (constant interval width)
- Returns n break points that create n+1 equal-width bins
- Handles missing values by skipping them
- Break points are in descending order (highest to lowest) to match create_bins function
- Each interval has the same width: (max - min) / (n+1)
"""
    function divide_into_n_parts(v::Vector{<:Real}, n::Int)
        # Remove missing values
        clean_data = collect(skipmissing(v))
        
        # Calculate min and max
        min_val = minimum(clean_data)
        max_val = maximum(clean_data)
        
        # Calculate interval width (n+1 intervals)
        interval_width = (max_val - min_val) / (n + 1)
        
        # Create break points in descending order (highest to lowest)
        [max_val - i * interval_width for i in 1:n]
    end