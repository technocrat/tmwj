using Pkg; Pkg.activate(@__DIR__)
using GeoDataFrames

using CSV
using ArchGDAL
using GeoMakie, CairoMakie
using DBInterface



df = CSV.read("data/Consumer_Airfare_Report__Table_1a_-_All_U.S._Airport_Pair_Markets.csv", DataFrame)
sort!(df, :city1)
function fix_coords(df::DataFrame, airport::String)
    pat = r"^[0-9.-]+"
    replace(airport, pat => "")
end
dropmissing!(df)
subset!(df, :Year => ByRow(x -> x == 2020))
select!(df, :Geocoded_City1, :Geocoded_City2, :passengers, :city1, :city2)
df.city2 = replace.(df.city2, r" \(Metropolitan Area\)" => "")
df.city1 = replace.(df.city1, r" \(Metropolitan Area\)" => "")

using ArchGDAL

function parse_coords_to_igeometry(coord_string::String)
    # Remove parentheses and split by comma
    cleaned = replace(coord_string, "(" => "", ")" => "")
    coords = split(cleaned, ",")
    
    # Parse latitude and longitude
    lat = parse(Float64, strip(coords[1]))
    lon = parse(Float64, strip(coords[2]))
    
    # Create ArchGDAL Point geometry (lon, lat order)
    return ArchGDAL.createpoint(lon, lat)
end

# Apply to your DataFrame column
df.geometry1 = parse_coords_to_igeometry.(df.Geocoded_City1)
df.geometry2 = parse_coords_to_igeometry.(df.Geocoded_City2)    

select!(df, :geometry1, :geometry2, :city1, :city2, :passengers)

function create_line_from_points(point1::ArchGDAL.IGeometry{ArchGDAL.wkbPoint}, point2::ArchGDAL.IGeometry{ArchGDAL.wkbPoint})
    # Create a linestring from two points
    line = ArchGDAL.createlinestring()
    ArchGDAL.addpoint!(line, ArchGDAL.getx(point1, 0), ArchGDAL.gety(point1, 0))
    ArchGDAL.addpoint!(line, ArchGDAL.getx(point2, 0), ArchGDAL.gety(point2, 0))
    return line
end

# Create line geometries from your point pairs
df.geometry_line = create_line_from_points.(df.geometry1, df.geometry2)

# Now group by the line geometry and sum passengers
grouped_df = combine(groupby(df, :geometry_line), 
                    :passengers => sum => :total_passengers,
                    :city1 => first => :origin_city,
                    :city2 => first => :destination_city)

import GeoDataFrames: GeoDataFrame

# Create a GeoDataFrame with your line geometries
gdf = GeoDataFrame(
    geometry = grouped_df.geometry_line,
    passengers = grouped_df.total_passengers,
    city1 = grouped_df.origin_city,
    city2 = grouped_df.destination_city
)

gdf = grouped_df
# Filter out Anchorage and Fairbanks routes
# Ensure columns are String and replace missing with ""
origin_city_clean = coalesce.(df.origin_city, "")
destination_city_clean = coalesce.(df.destination_city, "")

# Create boolean masks for each city
mask_anchorage_origin = occursin.("Anchorage, AK", origin_city_clean)
mask_anchorage_dest = occursin.("Anchorage, AK", destination_city_clean)
mask_fairbanks_origin = occursin.("Fairbanks, AK", origin_city_clean)
mask_fairbanks_dest = occursin.("Fairbanks, AK", destination_city_clean)

# Combine masks with element-wise OR
combined_mask = mask_anchorage_origin .| mask_anchorage_dest .| mask_fairbanks_origin .| mask_fairbanks_dest

# Invert to exclude these rows
ak_filter = .!combined_mask

# Filter the DataFrame
df = gdf[ak_filter, :]

using DataFrames
using GraphDataFrameBridge
using Graphs  # or MetaGraphs

# Convert to a simple undirected graph:
# Assuming your DataFrame is named df and has columns :origin_city and :destination_city

g = edgelist_graph(df, :origin_city, :destination_city, Graph)
# For a directed graph, use DiGraph instead of Graph

# For a directed graph:
g = SimpleDiGraph(df, :origin_city, :destination_city)

# For a graph with metadata (e.g., including total_passengers):
mg = MetaGraph(df, :origin_city, :destination_city)


fd =  DataFrame(Dict("start" => ["a", "b", "a", "d"],
"finish" => ["b", "c", "e", "e"],
"weights" => 1:4,
"extras" => 5:8))
dfg = DataFrame(Dict("start" => df.origin_city, "finish" => df.destination_city, "weights" => df.total_passengers))

g = edgelist_graph(dfg, :start, :finish, Graph)




# Set up the plot with Albers Equal Area projection
fig = Figure(resolution = (1200, 800))
ax = GeoAxis(fig[1, 1]; 
    dest = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +datum=WGS84")

# Simple plot without colors
lines!(ax, grouped_df.geometry_line, linewidth = 0.05)
fig