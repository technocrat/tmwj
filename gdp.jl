using Pkg; Pkg.activate()
using CairoMakie
using CSV
using DataFrames
using GeoDataFrames
using GeoMakie

# Load the data
println("Loading data...")
gdp_df = CSV.read("data/gdp.csv", DataFrame)
pop_df = CSV.read("data/pop_death_money.csv", DataFrame)
gdf = GeoDataFrames.read("data/cb_2018_us_state_500k.shp")

# Clean state names
gdp_df.State = strip.(gdp_df.State)
pop_df.State = strip.(pop_df.State)
gdf.NAME = strip.(gdf.NAME)

# Merge the data
df = innerjoin(gdp_df, pop_df, on=:State)
df = innerjoin(df, gdf, on=:State => :NAME)

# Calculate per capita GDP
df.per_capita = df.GDP ./ df.Population

# Remove Alaska and Hawaii for CONUS map
ak_hi = ["Alaska", "Hawaii"]
conus = subset(df, :State => ByRow(x -> x ∉ ak_hi))

println("Data loaded successfully!")
println("Number of states: ", nrow(conus))
println("GDP per capita range: ", minimum(conus.per_capita), " to ", maximum(conus.per_capita))

# Create the map with PuBu color scheme
fig = Figure(size = (3200, 1600), fontsize = 48)
titled = "GDP per Capita by State (2023)"
ga = GeoAxis(fig[1, 1];
    dest = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
    title = titled,
    aspect = DataAspect(),
    xgridvisible = false, ygridvisible = false,
    xticksvisible = false, yticksvisible = false,
    xticklabelsvisible = false, yticklabelsvisible = false
)

# Plot the map with per capita GDP using PuBu color scheme
poly!(ga, conus.geometry, color=conus.per_capita, colormap=:PuBu, strokecolor=:black, strokewidth=0.5)

# Add colorbar
Colorbar(fig[1, 2], label="GDP per Capita (USD)", colormap=:PuBu)

display(fig)

# Print summary statistics
# println("\nGDP per Capita Summary Statistics:")
# println("Average GDP per capita: $", round(mean(conus.per_capita), digits=0))
# println("Median GDP per capita: $", round(median(conus.per_capita), digits=0))
# println("Minimum GDP per capita: $", round(minimum(conus.per_capita), digits=0))
# println("Maximum GDP per capita: $", round(maximum(conus.per_capita), digits=0))

# Show top 5 states by GDP per capita
# println("\nTop 5 States by GDP per Capita:")
# top_5 = first(sort(conus, :per_capita, rev=true), 5)
# for (i, row) in enumerate(eachrow(top_5))
#     println("$i. $(row.State): $", round(row.per_capita, digits=0))
# end

# # Show bottom 5 states by GDP per capita
# println("\nBottom 5 States by GDP per Capita:")
# bottom_5 = first(sort(conus, :per_capita), 5)
# for (i, row) in enumerate(eachrow(bottom_5))
#     println("$i. $(row.State): $", round(row.per_capita, digits=0))
# end

println("\nMap created successfully with PuBu color scheme!") 