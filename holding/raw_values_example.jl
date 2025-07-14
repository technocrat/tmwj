using CairoMakie
using ColorSchemes
using DataFrames

# Include our custom functions for raw values
include("src/choropleth_raw_values.jl")

# Assuming you already have a DataFrame 'df' with :geometry, :Deaths, :Population, and :Expend columns
# If not, uncomment and modify the data loading section below

# # Load data if needed:
# using CSV
# using GeoDataFrames
# using Shapefile
# deaths_df = CSV.read("data/deaths.csv", DataFrame)
# shp = Shapefile.shapes("data/cb_2018_us_state_500k.shp")
# dbf = Shapefile.DBFTables.read("data/cb_2018_us_state_500k.dbf")
# gdf = GeoDataFrame(dbf, shp)
# df = innerjoin(gdf, deaths_df, on=:NAME => :State)

println("Creating choropleth maps using TRULY RAW VALUES (no normalization)...")

# Create the triple comparison using raw values
fig = plot_choropleth_triple_raw_comparison(df, 
                                           deaths_column=:Deaths,
                                           population_column=:Population,
                                           expenditures_column=:Expend,
                                           size=(1800, 600))

display(fig)

println("\nRaw value comparison complete!")
println("These maps use the actual raw numbers without any normalization or scaling.")
println("Each unique value gets its own distinct color from the colormap.")

# Alternative: Create individual maps if you prefer
println("\nCreating individual raw value maps...")

# Deaths
fig_deaths = plot_choropleth_raw_values(df, :Deaths, :Greens, 
                                       title="Deaths by State (Raw Values)", size=(800, 600))
display(fig_deaths)

# Population (if available)
if hasproperty(df, :Population)
    fig_pop = plot_choropleth_raw_values(df, :Population, :Blues, 
                                        title="Population by State (Raw Values)", size=(800, 600))
    display(fig_pop)
end

# Expenditures (if available)
if hasproperty(df, :Expend)
    fig_exp = plot_choropleth_raw_values(df, :Expend, :Reds, 
                                        title="Expenditures by State (Raw Values)", size=(800, 600))
    display(fig_exp)
end

println("\nIndividual maps complete!")
println("Each map preserves the actual scale differences between variables.")
println("This allows you to see the true magnitude differences while comparing spatial patterns.") 