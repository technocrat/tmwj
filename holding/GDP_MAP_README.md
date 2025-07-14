# GDP Thematic Map for US States

This project provides tools to create thematic maps showing GDP differences across US states using Julia.

## Files

- `src/gdp_thematic_map.jl` - Main library with functions for creating thematic maps
- `example_gdp_map.jl` - Simple example script that creates a GDP bar chart
- `data/` - Contains the data files:
  - `gdp.csv` - GDP data by state
  - `pop_death_money.csv` - Population and other economic data by state
  - `cb_2018_us_state_500k.shp` - Shapefile with state geometries

## Quick Start

### Option 1: Simple Bar Chart (Recommended for testing)

Run the example script to create a GDP bar chart:

```julia
include("example_gdp_map.jl")
```

This will:
- Load and merge the GDP and population data
- Create a bar chart showing GDP by state
- Color-code states based on GDP quantiles
- Display summary statistics

### Option 2: Full Thematic Map

For a complete choropleth map, use the main library:

```julia
include("src/gdp_thematic_map.jl")

# Load and merge data
df = load_and_merge_data("data/cb_2018_us_state_500k.shp", 
                        "data/pop_death_money.csv", 
                        "data/gdp.csv")

# Create GDP thematic map
fig, df_with_bins = create_gdp_thematic_map(df, 
                                           colormap=:viridis,
                                           title="US States GDP (2023)",
                                           bin_method=:quantiles,
                                           n_bins=5)

# Create GDP per capita map
fig2, df_per_capita = create_gdp_per_capita_map(df,
                                               colormap=:plasma,
                                               title="US States GDP per Capita (2023)")
```

## Functions

### `load_and_merge_data(gdf_path, pop_path, gdp_path)`
Loads and merges geometric data, population data, and GDP data.

### `create_gdp_bins(gdp_values, method=:quantiles; n_bins=5)`
Creates bins for GDP values using different methods:
- `:quantiles` - Equal number of states in each bin
- `:equal_width` - Equal GDP ranges
- `:natural_breaks` - Simplified natural breaks
- `:custom` - Custom break points

### `create_gdp_thematic_map(df; colormap=:viridis, title="...", bin_method=:quantiles, n_bins=5)`
Creates a choropleth map showing GDP differences across states.

### `create_gdp_per_capita_map(df; colormap=:plasma, title="...")`
Creates a choropleth map showing GDP per capita differences.

## Data Requirements

Your data should have the following structure:

### Geometric Data (GeoDataFrame)
- `:State` - State names
- `:geometry` - Geographic boundaries

### Population Data (DataFrame)
- `:State` - State names
- `:Population` - Population values

### GDP Data (DataFrame)
- `:State` - State names  
- `:GDP` - GDP values in USD

## Customization Options

### Color Schemes
Available color schemes include:
- `:viridis` - Sequential, perceptually uniform
- `:plasma` - Sequential, perceptually uniform
- `:Blues_9` - Sequential blue scale
- `:Reds_9` - Sequential red scale
- `:Set2_3` - Qualitative colors

### Binning Methods
- `:quantiles` - Equal number of states per bin
- `:equal_width` - Equal GDP ranges
- `:natural_breaks` - Natural clustering
- `:custom` - User-defined break points

## Example Output

The scripts will generate:
1. **Bar Chart** - Shows GDP by state with color coding
2. **Choropleth Map** - Geographic visualization of GDP differences
3. **Summary Statistics** - Total, average, and median GDP
4. **Top/Bottom States** - Rankings by GDP

## Dependencies

Required Julia packages:
- `DataFrames`
- `CSV`
- `CairoMakie`
- `ColorSchemes`
- `ArchGDAL` (for shapefile reading)
- `GeoDataFrames` (for geographic data)
- `GeoInterface` (for geometry handling)

Install with:
```julia
using Pkg
Pkg.add(["DataFrames", "CSV", "CairoMakie", "ColorSchemes", "ArchGDAL", "GeoDataFrames", "GeoInterface"])
```

## Troubleshooting

1. **Missing data files**: Ensure all CSV and shapefile files are in the `data/` directory
2. **Package errors**: Install required packages using `Pkg.add()`
3. **Geometry errors**: Check that shapefile is valid and contains proper geometries
4. **Memory issues**: For large datasets, consider reducing resolution or using fewer bins

## Advanced Usage

For more advanced visualizations, you can:
- Modify color schemes and binning methods
- Add additional data layers (e.g., population density)
- Create animated maps showing changes over time
- Export maps in various formats (PNG, PDF, SVG) 