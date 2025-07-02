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
    add_row_totals(df::DataFrame; 
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
function add_row_totals(df::DataFrame; 
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
    result_df = add_col_totals(df; total_col_name=total_col_name, cols_to_sum=cols_to_sum)
    
    # Then add row of column totals, including the new total column
    result_df = add_row_totals(result_df; total_row_name=total_row_name, cols_to_sum=cols_to_sum)
    
    # Update the grand total (bottom-right cell)
    if !isnothing(cols_to_sum) && !isempty(cols_to_sum)
        result_df[end, total_col_name] = sum(result_df[1:end-1, total_col_name])
    end
    
    return result_df
end

"""
    add_totals(df::DataFrame; total_row_name="Total", total_col_name="Total", cols_to_sum=nothing)

Add row and column totals to a DataFrame, creating margin totals.

# Arguments
- `df::DataFrame`: Input DataFrame to add totals to
- `total_row_name::String="Total"`: Name for the total row (appears in first column)
- `total_col_name::String="Total"`: Name for the total column header
- `cols_to_sum=nothing`: Vector of column names to sum. If `nothing`, automatically detects numeric columns

# Returns
- `DataFrame`: Copy of input DataFrame with added row totals (new column) and column totals (new row), including grand total

# Examples
```julia
using DataFrames

# Simple numeric DataFrame
df = DataFrame(A=[1, 2, 3], B=[4, 5, 6], C=[7, 8, 9])
result = add_totals(df)

# With custom names
result = add_totals(df, total_row_name="Sum", total_col_name="Row Sum")

# Specify which columns to sum
df_mixed = DataFrame(Name=["Alice", "Bob"], Score1=[85, 92], Score2=[78, 88], Grade=["A", "B"])
result = add_totals(df_mixed, cols_to_sum=["Score1", "Score2"])
```
"""
function add_totals(df::DataFrame; 
                   total_row_name="Total",
                   total_col_name="Total", 
                   cols_to_sum=nothing)
    
    # Create a copy of the input dataframe
    result_df = copy(df)
    
    # Determine which columns to sum
    if isnothing(cols_to_sum)
        cols_to_sum = names(df)[eltype.(eachcol(df)) .<: Number]
    end
    
    # Add row totals (column with sums across rows)
    if !isempty(cols_to_sum)
        result_df[!, total_col_name] = sum.(eachrow(result_df[:, cols_to_sum]))
    end
    
    # Add column totals (row with sums down columns)
    if !isempty(cols_to_sum)
        # Calculate totals for numeric columns
        total_row = Dict{String, Any}()
        
        # Add totals for numeric columns
        for col in cols_to_sum
            total_row[col] = sum(result_df[!, col])
        end
        
        # Handle non-numeric columns - use missing or empty string
        for col in names(result_df)
            if !(col in cols_to_sum) && col != total_col_name
                if col == names(result_df)[1]  # First column gets the total row name
                    total_row[col] = total_row_name
                else
                    total_row[col] = missing
                end
            end
        end
        
        # Add total for the total column (grand total)
        if total_col_name in names(result_df)
            total_row[total_col_name] = sum(result_df[!, total_col_name])
        end
        
        # Convert to DataFrame row and append
        total_df = DataFrame(total_row)
        result_df = vcat(result_df, total_df)
    end
    
    return result_df
end
function add_totals(df::DataFrame; 
                   total_row_name="Total",
                   total_col_name="Total", 
                   cols_to_sum=nothing)
    
    # Create a copy of the input dataframe
    result_df = copy(df)
    
    # Determine which columns to sum
    if isnothing(cols_to_sum)
        cols_to_sum = names(df)[eltype.(eachcol(df)) .<: Number]
    end
    
    # Add row totals (column with sums across rows)
    if !isempty(cols_to_sum)
        result_df[!, total_col_name] = sum.(eachrow(result_df[:, cols_to_sum]))
    end
    
    # Add column totals (row with sums down columns)
    if !isempty(cols_to_sum)
        # Calculate totals for numeric columns
        total_row = Dict{String, Any}()
        
        # Add totals for numeric columns
        for col in cols_to_sum
            total_row[col] = sum(result_df[!, col])
        end
        
        # Handle non-numeric columns - use missing or empty string
        for col in names(result_df)
            if !(col in cols_to_sum) && col != total_col_name
                if col == names(result_df)[1]  # First column gets the total row name
                    total_row[col] = total_row_name
                else
                    total_row[col] = missing
                end
            end
        end
        
        # Add total for the total column (grand total)
        if total_col_name in names(result_df)
            total_row[total_col_name] = sum(result_df[!, total_col_name])
        end
        
        # Convert to DataFrame row and append
        total_df = DataFrame(total_row)
        result_df = vcat(result_df, total_df)
    end
    
    return result_df
end
