using DataFrames, Statistics

# Create sample data
df = DataFrame(
    group = repeat(["A", "B", "C"], outer=4),
    value = rand(12)
)

# Group the data
grouped = groupby(df, :group)

# syntax for combine with multiple functions
result1 = combine(grouped, :value => sum => :sum_val, 
                           :value => mean => :mean_val, 
                           :value => std => :std_val)

# Alternative syntax using a vector of pairs
result2 = combine(grouped, [:value => sum => :sum_val, 
                           :value => mean => :mean_val, 
                           :value => std => :std_val])

# Another alternative using a function that returns multiple columns
function multiple_stats(x)
    return (sum_val = sum(x), mean_val = mean(x), std_val = std(x))
end

result3 = combine(grouped, :value => multiple_stats => AsTable)

using DataFrames

"""
    add_row_totals(df::DataFrame; 
                  total_col_name="Total",
                  cols_to_sum=nothing)
    
Add a column of row totals to a DataFrame.

# Arguments
- `df`: Input DataFrame
- `total_col_name`: Name for the new column with row totals (default: "Total")
- `cols_to_sum`: Columns to include in summation (default: all numeric columns)

# Returns
- A new DataFrame with an additional column containing row totals
"""
function add_row_totals(df::DataFrame; 
                      total_col_name="Total",
                      cols_to_sum=nothing)
    
    # Create a copy of the input dataframe
    result_df = copy(df)
    
    # Determine which columns to sum
    if isnothing(cols_to_sum)
        cols_to_sum = names(df)[eltype.(eachcol(df)) .<: Number]
    end
    
    # Add column with row totals
    if !isempty(cols_to_sum)
        result_df[!, total_col_name] = sum.(eachrow(result_df[:, cols_to_sum]))
    end
    
    return result_df
end

"""
    add_col_totals(df::DataFrame; 
                  total_row_name="Total",
                  cols_to_sum=nothing)
    
Add a row of column totals to a DataFrame.

# Arguments
- `df`: Input DataFrame
- `total_row_name`: Label for the row with column totals (default: "Total")
- `cols_to_sum`: Columns to include in summation (default: all numeric columns)

# Returns
- A new DataFrame with an additional row containing column totals
"""
function add_col_totals(df::DataFrame; 
                      total_row_name="Total",
                      cols_to_sum=nothing)
    
    # Create a copy of the input dataframe
    result_df = copy(df)
    
    # Determine which columns to sum
    if isnothing(cols_to_sum)
        cols_to_sum = names(df)[eltype.(eachcol(df)) .<: Number]
    end
    
    # Create a new row with column totals
    new_row = Dict{Symbol, Any}()
    
    # For each column in the dataframe
    for col in names(df)
        if col in cols_to_sum
            # Sum numeric columns
            new_row[Symbol(col)] = sum(skipmissing(df[!, col]))
        else
            # Use the margin name for non-numeric columns
            new_row[Symbol(col)] = total_row_name
        end
    end
    
    # Append the totals row
    push!(result_df, new_row)
    
    return result_df
end

"""
    add_totals(df::DataFrame; 
              total_row_name="Total", 
              total_col_name="Total",
              cols_to_sum=nothing)
    
Add both row and column totals to a DataFrame.

# Arguments
- `df`: Input DataFrame
- `total_row_name`: Label for the row with column totals (default: "Total")
- `total_col_name`: Name for the column with row totals (default: "Total")
- `cols_to_sum`: Columns to include in summation (default: all numeric columns)

# Returns
- A new DataFrame with both row and column totals added
"""
function add_totals(df::DataFrame; 
                  total_row_name="Total", 
                  total_col_name="Total",
                  cols_to_sum=nothing)
    
    # First add column of row totals
    result_df = add_row_totals(df; total_col_name=total_col_name, cols_to_sum=cols_to_sum)
    
    # Then add row of column totals, including the new total column
    result_df = add_col_totals(result_df; total_row_name=total_row_name, cols_to_sum=cols_to_sum)
    
    # Update the grand total (bottom-right cell)
    if !isnothing(cols_to_sum) && !isempty(cols_to_sum)
        result_df[end, total_col_name] = sum(result_df[1:end-1, total_col_name])
    end
    
    return result_df
end