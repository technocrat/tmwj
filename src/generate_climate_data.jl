using Pkg; Pkg.activate(@__DIR__)
using DataFrames
## 1. Simple Generated Climate Data (No external dependencies)
"""
Generate synthetic global temperature anomaly data
For testing layouts without external data dependencies
"""
function generate_climate_data()
    # Create coordinate grids
    lons = -180:2:180
    lats = -90:2:90
    
    # Generate synthetic temperature anomaly field
    temp_anomaly = [
        2 * exp(-((lon/60)^2 + (lat/30)^2)) + 
        0.5 * sin(lon/20) * cos(lat/15) +
        0.3 * randn()
        for lon in lons, lat in lats
    ]
    
    # Generate time series data
    years = 1980:2024
    global_mean = cumsum(0.02 .+ 0.1 * randn(length(years)))
    
    # City locations for annotations
    cities = DataFrame(
        name = ["New York", "London", "Tokyo", "Sydney", "Cairo", "São Paulo"],
        lon = [-74.0, 0.1, 139.7, 151.2, 31.2, -46.6],
        lat = [40.7, 51.5, 35.7, -33.9, 30.0, -23.5],
        value = [2.1, 1.8, 2.5, 1.9, 3.2, 2.7]
    )
    
    return (
        lons = lons,
        lats = lats,
        field = temp_anomaly,
        years = years,
        timeseries = global_mean,
        cities = cities
    )
end
