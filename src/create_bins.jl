"""
    create_bins(population, breaks)

Create bin assignments for population values based on break points.

# Arguments
- `population::Real`: A single population value to assign to a bin
- `breaks::Vector{<:Real}`: Vector of break points in descending order (highest to lowest)

# Returns
- `Int`: Bin number (1-based index) corresponding to the population value

# Examples
```julia
# Create bins with break points: 39M, 29M, 18M, 9M, 1M
breaks = [39e6, 29e6, 18e6, 9e6, 1e6]
bin = create_bins(25e6, breaks)  # Returns 2 (between 29M and 18M)

# Apply to a vector of populations
populations = [40e6, 15e6, 5e6, 0.5e6]
bins = create_bins.(populations, Ref(breaks))  # Returns [1, 3, 5, 6]
```

# Notes
- Break points should be in descending order (highest to lowest)
- Populations >= first break point get bin 1
- Populations < last break point get bin length(breaks) + 1
- Uses broadcasting with `Ref()` when applying to vectors
"""
function create_bins(population, breaks)
    for (i, break_point) in enumerate(breaks)
        if population < break_point
            return i
        end
    end
    return length(breaks) + 1
end

eye_bins = [39e6,29e6,18e6,9e6,1e6]
std_bins = [10e6,5e6,2e6]
df.bin_by_eye = create_bins.(df.Population, Ref(eye_bins))
df.bin_standard = create_bins.(df.Population, Ref(std_bins))






