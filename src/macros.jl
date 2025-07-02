"""
Macros for the TMWJ codebase to reduce code duplication and improve consistency.

This module provides macros for:
- Data validation (@validate)
- Geometry processing (@process_geometry)
- DataFrame operations (@df_ops)
- Plot configuration (@plot_config)
- Data binning (@bin_data)
- Color scheme handling (@color_scheme)
- Error handling (@safe_operation)
- Performance timing (@timed)
"""

using DataFrames
using CairoMakie
using ColorSchemes
using GeoInterface
using Statistics

# =============================================================================
# VALIDATION MACRO
# =============================================================================

"""
    @validate condition message

Validate a condition and throw an ArgumentError with the given message if false.

# Examples
```julia
@validate isfile(file_name) "File '$file_name' not found"
@validate length(data) > 0 "Data cannot be empty"
@validate sheet <= length(available_sheets) "Sheet index out of bounds"
```
"""
macro validate(condition, message)
    quote
        if !$(esc(condition))
            throw(ArgumentError($(esc(message))))
        end
    end
end

# =============================================================================
# GEOMETRY PROCESSING MACRO
# =============================================================================

"""
    @process_geometry geom coords color_func

Process geometry coordinates and apply a color function to each polygon ring.

# Arguments
- `geom`: Geometry object
- `coords`: Coordinates from GeoInterface.coordinates(geom)
- `color_func`: Function that takes bin index and returns color

# Examples
```julia
@process_geometry geom coords (bin) -> colors[bin]
```
"""
macro process_geometry(geom, coords, color_func)
    quote
        if GeoInterface.isgeometry($(esc(geom)))
            coords = GeoInterface.coordinates($(esc(geom)))
            if !isempty(coords)
                if GeoInterface.geomtrait($(esc(geom))) isa GeoInterface.PolygonTrait
                    for ring in coords
                        if !isempty(ring)
                            poly!(ax, ring, color=$(esc(color_func)), strokecolor=:black, strokewidth=0.5)
                        end
                    end
                elseif GeoInterface.geomtrait($(esc(geom))) isa GeoInterface.MultiPolygonTrait
                    for polygon in coords
                        for ring in polygon
                            if !isempty(ring)
                                poly!(ax, ring, color=$(esc(color_func)), strokecolor=:black, strokewidth=0.5)
                            end
                        end
                    end
                end
            end
        end
    end
end

# =============================================================================
# DATAFRAME OPERATIONS MACRO
# =============================================================================

"""
    @df_ops df operations...

Apply a sequence of DataFrame operations.

# Examples
```julia
@df_ops df begin
    copy
    add_column :total => sum.(eachrow(_[:, cols_to_sum]))
    filter :total => _ > 0
end
```
"""
macro df_ops(df, operations)
    quote
        result_df = copy($(esc(df)))
        $(esc(operations))
        result_df
    end
end

# Helper functions for DataFrame operations
function add_column!(df::DataFrame, col_sym::Symbol, values)
    df[!, col_sym] = values
    return df
end

function add_column!(df::DataFrame, col_sym::Symbol, func::Function)
    df[!, col_sym] = func(df)
    return df
end

# =============================================================================
# PLOT CONFIGURATION MACRO
# =============================================================================

"""
    @plot_config fig ax size fontsize config_block

Configure a Makie plot with standard settings.

# Arguments
- `fig`: Figure variable name
- `ax`: Axis variable name  
- `size`: Tuple of (width, height)
- `fontsize`: Font size
- `config_block`: Block with axis configuration

# Examples
```julia
@plot_config fig ax (800, 600) 24 begin
    xlabel = "Population"
    ylabel = "Frequency"
    title = "Distribution"
end
```
"""
macro plot_config(fig, ax, size, fontsize, config_block)
    quote
        $(esc(fig)) = Figure(size = $(esc(size)), fontsize = $(esc(fontsize)))
        $(esc(ax)) = Axis($(esc(fig))[1, 1]; $(esc(config_block)))
    end
end

# =============================================================================
# DATA BINNING MACRO
# =============================================================================

"""
    @bin_data data method output_col

Create bins for data using specified method and assign to output column.

# Arguments
- `data`: Data to bin
- `method`: Binning method (:quantiles, :equal_width, :natural_breaks, :custom)
- `output_col`: Symbol for output column name

# Examples
```julia
@bin_data df.GDP :quantiles :bin
@bin_data df.Population :equal_width :pop_bin n_bins=10
```
"""
macro bin_data(data, method, output_col; kwargs...)
    quote
        # Create bins based on method
        valid_data = filter(!isnan, $(esc(data)))
        
        breaks = if $(esc(method)) == :quantiles
            n_bins = get($(kwargs), :n_bins, 5)
            quantile(valid_data, range(0, 1, length=n_bins+1))
        elseif $(esc(method)) == :equal_width
            n_bins = get($(kwargs), :n_bins, 5)
            min_val, max_val = extrema(valid_data)
            range(min_val, max_val, length=n_bins+1)
        elseif $(esc(method)) == :natural_breaks
            quantile(valid_data, [0, 0.2, 0.4, 0.6, 0.8, 1.0])
        elseif $(esc(method)) == :custom
            get($(kwargs), :breaks, [0, 1e11, 5e11, 1e12, 2e12, Inf])
        else
            error("Unknown binning method: $($(esc(method)))")
        end
        
        breaks = unique(breaks)
        
        # Assign bins
        bins = zeros(Int, length($(esc(data))))
        for (i, val) in enumerate($(esc(data)))
            if isnan(val)
                bins[i] = 0
            else
                for (j, break_point) in enumerate(breaks)
                    if val <= break_point
                        bins[i] = j
                        break
                    end
                end
                if bins[i] == 0
                    bins[i] = length(breaks)
                end
            end
        end
        
        # Assign to output column
        $(esc(output_col)) = bins
    end
end

# =============================================================================
# COLOR SCHEME MACRO
# =============================================================================

"""
    @color_scheme colormap fallback

Get a color scheme with fallback handling.

# Arguments
- `colormap`: Color scheme name or symbol
- `fallback`: Fallback color scheme if primary not found

# Examples
```julia
@color_scheme :viridis fallback=:plasma
@color_scheme colormap fallback=:viridis
```
"""
macro color_scheme(colormap; fallback=:viridis)
    quote
        colors = get(ColorSchemes.colorschemes, $(esc(colormap)), ColorSchemes.colorschemes[$(esc(fallback))])
        if typeof(colors) <: Symbol
            colors = ColorSchemes.colorschemes[colors]
        end
        colors
    end
end

# =============================================================================
# ERROR HANDLING MACRO
# =============================================================================

"""
    @safe_operation message block

Execute a block of code with error handling.

# Arguments
- `message`: Error message prefix
- `block`: Code block to execute

# Examples
```julia
@safe_operation "Failed to process GDP data" begin
    result = create_gdp_thematic_map(df)
    return result
end
```
"""
macro safe_operation(message, block)
    quote
        try
            $(esc(block))
        catch e
            error($(esc(message)) * ": " * string(e))
        end
    end
end

# =============================================================================
# PERFORMANCE TIMING MACRO
# =============================================================================

"""
    @timed operation_name block

Time the execution of a code block.

# Arguments
- `operation_name`: Name of the operation for logging
- `block`: Code block to time

# Examples
```julia
@timed "GDP map creation" begin
    create_gdp_thematic_map(df)
end
```
"""
macro timed(operation_name, block)
    quote
        println("Starting: " * $(esc(operation_name)))
        start_time = time()
        result = $(esc(block))
        end_time = time()
        println("Completed: " * $(esc(operation_name)) * " in " * @sprintf("%.3f", end_time - start_time) * " seconds")
        result
    end
end

# =============================================================================
# ADDITIONAL UTILITY MACROS
# =============================================================================

"""
    @skip_missing data

Skip missing values in data processing.

# Examples
```julia
@skip_missing df.GDP
```
"""
macro skip_missing(data)
    quote
        collect(skipmissing($(esc(data))))
    end
end

"""
    @format_number value format

Format a number with specified format string.

# Examples
```julia
@format_number gdp_value "%.1fB"
```
"""
macro format_number(value, format)
    quote
        @sprintf($(esc(format)), $(esc(value)))
    end
end

"""
    @log_operation operation_name args...

Log operation execution with arguments.

# Examples
```julia
@log_operation "create_bins" population breaks
```
"""
macro log_operation(operation_name, args...)
    arg_names = [string(arg) for arg in args]
    arg_values = [esc(arg) for arg in args]
    
    quote
        println("Executing: " * $(esc(operation_name)) * " with args: " * 
                join([$(arg_names[i]) * "=" * string($(arg_values[i])) for i in 1:length($(args))], ", "))
        $(esc(operation_name))($(arg_values...))
    end
end

# =============================================================================
# EXPORTS
# =============================================================================

export @validate, @process_geometry, @df_ops, @plot_config, @bin_data, 
       @color_scheme, @safe_operation, @timed, @skip_missing, @format_number, @log_operation 