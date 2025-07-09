# Example Datasets for Makie Map Layout Tutorial
using Pkg; Pkg.activate(@__DIR__)
using CairoMakie, GeoMakie
using ColorSchemes
using DataFrames
using Downloads
using NCDatasets
using CSV, DataFrames
using Statistics

# Custom diverging palette from low in blue to high in red
BuRd_6 = reverse(colorschemes[:RdBu_6])

include("src/generate_climate_data.jl")


## 2. Earth Topography Data (Built into GeoMakie)
"""
Use GeoMakie's built-in Earth topography
Excellent for demonstrating colorbars and projections
"""
function load_earth_topography()
    # GeoMakie provides ETOPO1 data
    lons = -180:1:180
    lats = -90:1:90
    
    # Note: In actual use, GeoMakie.earth() provides this
    # Here we simulate similar data
    topo = [
        -4000 * exp(-((lon/60)^2 + (lat/30)^2)) + 
        1000 * sin(lon/40) * cos(lat/20) +
        500 * randn()
        for lon in lons, lat in lats
    ]
    
    return (lons = lons, lats = lats, elevation = topo)
end

## 3. Natural Earth Features (Via GeoMakie)
"""
Load country boundaries and major cities
For demonstrating annotations and multi-panel layouts
"""
function load_natural_earth_features()
    # Major world cities for demonstration
    major_cities = DataFrame(
        name = ["Tokyo", "Delhi", "Shanghai", "São Paulo", "Mumbai", 
                "Beijing", "Cairo", "Dhaka", "Mexico City", "Osaka"],
        lon = [139.69, 77.23, 121.47, -46.63, 72.88, 
               116.40, 31.24, 90.41, -99.13, 135.50],
        lat = [35.68, 28.61, 31.23, -23.55, 19.08, 
               39.90, 30.04, 23.81, 19.43, 34.69],
        population = [37.4, 32.9, 28.5, 22.6, 20.7, 
                     20.5, 20.5, 18.6, 21.8, 19.0]  # millions
    )
    
    # Ocean regions for labels
    ocean_labels = DataFrame(
        name = ["Pacific Ocean", "Atlantic Ocean", "Indian Ocean", 
                "Arctic Ocean", "Southern Ocean"],
        lon = [-150, -30, 80, 0, 0],
        lat = [0, 0, -20, 80, -60]
    )
    
    return (cities = major_cities, oceans = ocean_labels)
end

## 4. Regional Climate Indices
"""
Generate regional climate index data
For demonstrating multi-panel dashboards
"""
function generate_regional_indices()
    years = 1950:2024
    
    # Different climate indices
    indices = DataFrame(
        year = years,
        nao = cumsum(0.3 * randn(length(years))),      # North Atlantic Oscillation
        enso = 2 * sin.(2π * years / 7) + randn(length(years)), # El Niño
        pdo = cumsum(0.2 * randn(length(years))),      # Pacific Decadal
        amo = 0.5 * sin.(2π * years / 20) + 0.3 * randn(length(years)) # Atlantic Multidecadal
    )
    
    # Regional data (e.g., for North America)
    regional_lons = -130:2:-60
    regional_lats = 20:2:60
    regional_field = [
        sin((lon + 95) / 15) * cos((lat - 40) / 10) + 0.2 * randn()
        for lon in regional_lons, lat in regional_lats
    ]
    
    return (
        indices = indices,
        regional_lons = regional_lons,
        regional_lats = regional_lats,
        regional_field = regional_field
    )
end

## 5. Download Real Climate Data (Optional)
"""
Download actual climate data from NOAA
Requires internet connection but provides real-world data
"""
# function download_real_climate_data()
#     # Sea Surface Temperature anomalies from NOAA
#     url = "https://psl.noaa.gov/data/correlation/amon.us.data"
    
#     try
#         # Download data
#         data = Downloads.download(url)
        
#         # Parse the data (simplified example)
#         # In practice, you'd parse the specific format
        
#         println("Successfully downloaded NOAA data")
#         return true, dat
#     catch e
#         println("Could not download data: ", e)
#         return false
#     end
# end

## Complete Example: Create Multi-Panel Climate Dashboard
"""
Comprehensive example using the generated datasets
"""
function create_climate_dashboard_example()
    # Generate all necessary data
    climate = generate_climate_data()
    topo = load_earth_topography()
    features = load_natural_earth_features()
    regional = generate_regional_indices()
    
    # Create the dashboard
    f = Figure(size = (1400, 900), figure_padding = 20)
    
    # Main title
    Label(f[0, :], "Global Climate Analysis Dashboard (synthetic data)", 
          fontsize = 24, font = :bold)
    
    # 1. Main map: Temperature anomalies
    ga_main = GeoAxis(
        f[1, 1:2], 
        dest = "+proj=robin",
        title = "Global Temperature Anomalies (°C)"
    )
    
    # Plot temperature field
    sf = surface!(ga_main, climate.lons, climate.lats, climate.field,
                  colormap = BuRd_6, colorrange = (-3, 3))
    
    # Add coastlines
    lines!(ga_main, GeoMakie.coastlines(), color = :gray50, linewidth = 0.5)
    
    # Add city markers
    scatter!(ga_main, climate.cities.lon, climate.cities.lat,
             color = climate.cities.value, 
             colormap = BuRd_6,
             colorrange = (-3, 3),
             markersize = 10,
             strokecolor = :black,
             strokewidth = 1)
    
    # City labels
    for row in eachrow(climate.cities)
        text!(ga_main, row.lon, row.lat + 5, text = row.name,
              fontsize = 10, align = (:center, :bottom))
    end
    
    # 2. Regional detail map
    ga_regional = GeoAxis(
        f[1, 3],
        dest = "+proj=lcc +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96",
        title = "North America Detail"
    )
    
    surface!(ga_regional, regional.regional_lons, regional.regional_lats, 
             regional.regional_field, colormap = :viridis)
    lines!(ga_regional, GeoMakie.coastlines(), color = :white, linewidth = 0.5)
    
    # 3. Time series plot
    ax_ts = Axis(f[2, 1:2],
                 xlabel = "Year",
                 ylabel = "Temperature Anomaly (°C)",
                 title = "Global Mean Temperature Evolution")
    
    lines!(ax_ts, climate.years, climate.timeseries, 
           color = :red, linewidth = 2, label = "Annual mean")
    
    # Add trend line
    X = [ones(length(climate.years)) climate.years .- mean(climate.years)]
    β = X \ climate.timeseries
    trend = X * β
    lines!(ax_ts, climate.years, trend, 
           color = :black, linewidth = 2, linestyle = :dash, 
           label = "Linear trend")
    
    axislegend(ax_ts, position = :lt)
    
    # 4. Climate indices panel
    ax_indices = Axis(f[2, 3],
                      xlabel = "Year", 
                      ylabel = "Index Value",
                      title = "Climate Oscillations")
    
    lines!(ax_indices, regional.indices.year, regional.indices.nao, 
           label = "NAO", linewidth = 2)
    lines!(ax_indices, regional.indices.year, regional.indices.enso, 
           label = "ENSO", linewidth = 2)
    
    axislegend(ax_indices, position = :rt, labelsize = 10)
    
    # 5. Colorbar for main map
    cb = Colorbar(f[1, 4], sf,
                  label = "Temperature Anomaly (°C)",
                  height = Relative(0.7))
    
    # 6. Statistics panel
    stats_grid = GridLayout()
    f[3, 1:2] = stats_grid
    
    Label(stats_grid[1, 1], "Summary Statistics", 
          fontsize = 16, font = :bold)
    
    stats_text = """
    Global Mean Anomaly: $(round(mean(climate.field), digits=2))°C
    Maximum Anomaly: $(round(maximum(climate.field), digits=2))°C
    Trend: +$(round(β[2], digits=3))°C/year
    Affected Cities: $(count(c -> c.value > 2.0, eachrow(climate.cities)))
    """
    
    Label(stats_grid[2, 1], stats_text, 
          fontsize = 12, justification = :left)
    
    # Layout adjustments
    colsize!(f.layout, 1, Auto(2))
    colsize!(f.layout, 2, Auto(2))
    colsize!(f.layout, 3, Auto(1.5))
    colsize!(f.layout, 4, Fixed(80))
    
    rowsize!(f.layout, 1, Auto(2))
    rowsize!(f.layout, 2, Auto(1.5))
    rowsize!(f.layout, 3, Fixed(100))
    
    colgap!(f.layout, 10)
    rowgap!(f.layout, 10)
    
    return f
end

## Quick test example
"""
Simple example to verify everything works
"""
function test_simple_map()
    data = generate_climate_data()
    
    f = Figure(size = (800, 500))
    
    ga = GeoAxis(f[1, 1], dest = "+proj=moll")
    surface!(ga, data.lons, data.lats, data.field, colormap = BuRd_6)
    lines!(ga, GeoMakie.coastlines(), color = :black, linewidth = 0.5)
    
    Colorbar(f[1, 2], limits = extrema(data.field), 
             label = "Temperature (°C)")
    
    colsize!(f.layout, 1, Auto(4))
    colsize!(f.layout, 2, Auto(1))
    
    return f
end

# Run the examples
fig = test_simple_map()
dashboard = create_climate_dashboard_example()