"""
    @ensure_types(df, type_specs...)

Ensure that specified columns in a DataFrame have the correct data types by performing
automatic type conversions.

# Arguments
- `df`: The DataFrame to modify
- `type_specs...`: Variable number of type specifications in the format `column::Type`

# Type Specifications
Each type specification should be in the format `column::Type` where:
- `column` is the column name (Symbol or String)
- `Type` is the target Julia type (e.g., `Int`, `Float64`, `String`)

# Supported Conversions
- String to Integer: Uses `parse()` to convert string representations of numbers
- String to Float: Uses `parse()` to convert string representations of floating-point numbers  
- Float to Integer: Uses `round()` to convert floating-point numbers to integers
- Other conversions: Uses `convert()` for general type conversions

# Examples
```julia
# Convert Population to Int and Expend to Float64
@ensure_types df Population::Int Expend::Float64

# Convert multiple columns at once
@ensure_types df Deaths::Int Population::Int Expend::Float64
```

# Notes
- The macro modifies the DataFrame in-place
- Prints progress messages for successful conversions
- Issues warnings for columns that don't exist
- Throws errors for conversion failures
- Returns the modified DataFrame

# See Also
- `convert()`: Base Julia function for type conversions
- `parse()`: Base Julia function for parsing strings to numbers
- `round()`: Base Julia function for rounding numbers
"""
macro ensure_types(df, type_specs...)
    conversions = []
    
    for spec in type_specs
        if spec isa Expr && spec.head == :(::) && length(spec.args) == 2
            col = spec.args[1]
            typ = spec.args[2]
            
            push!(conversions, quote
                local df_ref = $(esc(df))
                local col_str = $(string(col))
                local target_type = $(esc(typ))
                
                if col_str in names(df_ref)
                    try
                        println("Converting column '$col_str' to $target_type")
                        
                        if target_type <: Integer && eltype(df_ref[!, col_str]) <: AbstractString
                            # Parse strings to integers
                            df_ref[!, col_str] = parse.(target_type, df_ref[!, col_str])
                        elseif target_type <: AbstractFloat && eltype(df_ref[!, col_str]) <: AbstractString
                            # Parse strings to floats
                            df_ref[!, col_str] = parse.(target_type, df_ref[!, col_str])
                        elseif target_type <: Integer && eltype(df_ref[!, col_str]) <: AbstractFloat
                            # Convert floats to integers (with rounding)
                            df_ref[!, col_str] = round.(target_type, df_ref[!, col_str])
                        else
                            # Use convert for other cases
                            df_ref[!, col_str] = convert.(target_type, df_ref[!, col_str])
                        end
                        
                        println("✓ Successfully converted column '$col_str'")
                    catch e
                        error("Failed to convert column '$col_str' to $target_type: $e")
                    end
                else
                    @warn "Column '$col_str' not found in DataFrame"
                end
            end)
        end
    end
    
    return quote
        $(conversions...)
        $(esc(df))
    end
end
