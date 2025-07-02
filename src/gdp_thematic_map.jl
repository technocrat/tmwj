using DataFrames
using CSV
using CairoMakie
using ColorSchemes
using ArchGDAL
using GeoDataFrames
using GeoInterface

"""
    load_and_merge_data(gdf_path, pop_path, gdp_path)

Load and merge the geometric data, population data, and GDP data.
"""
function load_and_merge_data(gdf_path, pop_path, gdp_path)
    # Load the data
    gdf = GeoDataFrame(CSV.read(gdf_path, DataFrame))
    pop_df = CSV.read(pop_path, DataFrame)
    gdp_df = CSV.read(gdp_path, DataFrame)
    
    # Clean state names (remove extra spaces and ensure consistency)
    gdf.State = strip.(gdf.State)
    pop_df.State = strip.(pop_df.State)
    gdp_df.State = strip.(gdp_df.State)
    
    # Merge population data
    merged_df = leftjoin(gdf, pop_df, on=:State)
    
    # Merge GDP data
    merged_df = leftjoin(merged_df, gdp_df, on=:State)
    
    return merged_df
end

"""
    create_gdp_bins(gdp_values, method=:quantiles; n_bins=5)

Create bins for GDP values using different methods.
- `method`: :quantiles, :equal_width, :natural_breaks, or :custom
- `n_bins`: number of bins to create
"""
function create_gdp_bins(gdp_values, method=:quantiles; n_bins=5)
    valid_gdp = filter(!isnan, gdp_values)
    
    if method == :quantiles
        # Create quantile-based breaks
        breaks = quantile(valid_gdp, range(0, 1, length=n_bins+1))
        breaks = unique(breaks)
    elseif method == :equal_width
        # Create equal-width breaks
        min_val, max_val = extrema(valid_gdp)
        breaks = range(min_val, max_val, length=n_bins+1)
    elseif method == :natural_breaks
        # Use natural breaks (Jenks) - simplified version
        breaks = quantile(valid_gdp, [0, 0.2, 0.4, 0.6, 0.8, 1.0])
        breaks = unique(breaks)
    elseif method == :custom
        # Custom breaks based on GDP magnitude
        breaks = [0, 1e11, 5e11, 1e12, 2e12, Inf]  # 0, 100B, 500B, 1T, 2T+
    else
        error("Unknown binning method: $method")
    end
    
    return breaks
end

"""
    assign_bins(values, breaks)

Assign values to bins based on break points.
"""
function assign_bins(values, breaks)
    bins = zeros(Int, length(values))
    for (i, val) in enumerate(values)
        if isnan(val)
            bins[i] = 0  # Missing data
        else
            for (j, break_point) in enumerate(breaks)
                if val <= break_point
                    bins[i] = j
                    break
                end
            end
            if bins[i] == 0
                bins[i] = length(breaks)  # Above all breaks
            end
        end
    end
    return bins
end

"""
    format_gdp_label(gdp_value)

Format GDP values for display (convert to billions/trillions).
"""
function format_gdp_label(gdp_value)
    if gdp_value >= 1e12
        return @sprintf("%.1fT", gdp_value / 1e12)
    elseif gdp_value >= 1e9
        return @sprintf("%.1fB", gdp_value / 1e9)
    else
        return @sprintf("%.0fM", gdp_value / 1e6)
    end
end

"""
    create_gdp_thematic_map(df; 
                           colormap=:viridis, 
                           title="US States GDP Thematic Map",
                           bin_method=:quantiles,
                           n_bins=5)

Create a thematic map showing GDP differences across US states.
"""
function create_gdp_thematic_map(df; 
                               colormap=:viridis, 
                               title="US States GDP Thematic Map",
                               bin_method=:quantiles,
                               n_bins=5)
    
    # Create bins for GDP values
    breaks = create_gdp_bins(df.GDP, bin_method, n_bins=n_bins)
    df.bin = assign_bins(df.GDP, breaks)
    
    # Create color scheme
    colors = get(ColorSchemes.colorschemes, colormap, ColorSchemes.viridis)
    if typeof(colors) <: Symbol
        colors = ColorSchemes.colorschemes[colors]
    end
    
    # Create the map
    fig = Figure(resolution=(1200, 800))
    ax = Axis(fig[1, 1], 
              title=title,
              xticksvisible=false, 
              yticksvisible=false,
              xticklabelsvisible=false, 
              yticklabelsvisible=false)
    
    # Plot each state with its GDP color
    for (i, row) in enumerate(eachrow(df))
        if !isnan(row.GDP) && row.bin > 0
            # Get geometry and convert to coordinates
            geom = row.geometry
            if GeoInterface.isgeometry(geom)
                coords = GeoInterface.coordinates(geom)
                if !isempty(coords)
                    # Handle different geometry types
                    if GeoInterface.geomtrait(geom) isa GeoInterface.PolygonTrait
                        for ring in coords
                            if !isempty(ring)
                                poly!(ax, ring, color=colors[row.bin], strokecolor=:black, strokewidth=0.5)
                            end
                        end
                    elseif GeoInterface.geomtrait(geom) isa GeoInterface.MultiPolygonTrait
                        for polygon in coords
                            for ring in polygon
                                if !isempty(ring)
                                    poly!(ax, ring, color=colors[row.bin], strokecolor=:black, strokewidth=0.5)
                                end
                            end
                        end
                    end
                end
            end
        else
            # Missing data - plot in gray
            geom = row.geometry
            if GeoInterface.isgeometry(geom)
                coords = GeoInterface.coordinates(geom)
                if !isempty(coords)
                    if GeoInterface.geomtrait(geom) isa GeoInterface.PolygonTrait
                        for ring in coords
                            if !isempty(ring)
                                poly!(ax, ring, color=:lightgray, strokecolor=:black, strokewidth=0.5)
                            end
                        end
                    elseif GeoInterface.geomtrait(geom) isa GeoInterface.MultiPolygonTrait
                        for polygon in coords
                            for ring in polygon
                                if !isempty(ring)
                                    poly!(ax, ring, color=:lightgray, strokecolor=:black, strokewidth=0.5)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    # Create colorbar
    valid_bins = unique(filter(x -> x > 0, df.bin))
    if !isempty(valid_bins)
        # Create dummy heatmap for colorbar
        dummy_data = reshape(valid_bins, length(valid_bins), 1)
        hm = heatmap!(ax, dummy_data, colormap=colors, visible=false)
        Colorbar(fig[1, 2], hm, 
                label="GDP (USD)", 
                ticks=valid_bins,
                ticklabels=[format_gdp_label(breaks[i]) for i in valid_bins])
    end
    
    # Add legend for missing data
    if any(df.bin .== 0)
        Legend(fig[1, 3], 
              [PolyElement(color=:lightgray, strokecolor=:black)],
              ["No Data"],
              "Missing Data")
    end
    
    display(fig)
    return fig, df
end

"""
    create_gdp_per_capita_map(df; 
                             colormap=:plasma, 
                             title="US States GDP per Capita Thematic Map")

Create a thematic map showing GDP per capita differences across US states.
"""
function create_gdp_per_capita_map(df; 
                                 colormap=:plasma, 
                                 title="US States GDP per Capita Thematic Map")
    
    # Calculate GDP per capita
    df.GDP_per_capita = df.GDP ./ df.Population
    
    # Create bins for GDP per capita
    breaks = create_gdp_bins(df.GDP_per_capita, :quantiles, n_bins=5)
    df.bin_per_capita = assign_bins(df.GDP_per_capita, breaks)
    
    # Create the map using the same function but with per capita data
    return create_gdp_thematic_map(df, 
                                 colormap=colormap, 
                                 title=title,
                                 bin_method=:quantiles,
                                 n_bins=5)
end

# Example usage and testing
if abspath(PROGRAM_FILE) == @__FILE__
    println("Loading and merging data...")
    
    # Load data (adjust paths as needed)
    gdf_path = "data/cb_2018_us_state_500k.shp"
    pop_path = "data/pop_death_money.csv"
    gdp_path = "data/gdp.csv"
    
    try
        # Load and merge data
        df = load_and_merge_data(gdf_path, pop_path, gdp_path)
        
        println("Data loaded successfully!")
        println("Number of states: ", nrow(df))
        println("GDP range: ", minimum(df.GDP), " to ", maximum(df.GDP))
        
        # Create GDP thematic map
        println("Creating GDP thematic map...")
        fig1, df_with_bins = create_gdp_thematic_map(df, 
                                                    colormap=:viridis,
                                                    title="US States GDP (2023)",
                                                    bin_method=:quantiles,
                                                    n_bins=5)
        
        # Create GDP per capita map
        println("Creating GDP per capita thematic map...")
        fig2, df_per_capita = create_gdp_per_capita_map(df,
                                                       colormap=:plasma,
                                                       title="US States GDP per Capita (2023)")
        
        println("Maps created successfully!")
        
    catch e
        println("Error: ", e)
        println("Make sure all data files are available in the correct paths.")
    end
end

export load_and_merge_data, create_gdp_bins, assign_bins, create_gdp_thematic_map, create_gdp_per_capita_map 