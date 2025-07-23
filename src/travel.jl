using CSV, CairoMakie, Colors, DataFrames, Dates, GeoDataFrames, GeoMakie, 
GeoInterface

include("src/constants.jl")

df = CSV.read("data/mariners.csv", DataFrame)

tigerline_file = "data/2024_shp/cb_2024_us_state_500k.shp"
full_geo = GeoDataFrames.read(tigerline_file)

geo = subset(full_geo, :STUSPS => ByRow(x -> x ∉ ["AK","HI","PR","VI","GU","AS","MP","UM"]))
geo = select(geo, :geometry, :GEOID)
rename!(geo, :GEOID => :geoid)



# Create IGeometry points from lat/lon coordinates
function parse_point(str)
    cleaned = replace(str, r"[^0-9.,-]" => "")  # keep only numbers, dot, comma, minus
    parts = split(cleaned, ",")
    lon = parse(Float64, parts[1])
    lat = parse(Float64, parts[2])
    return Point((lon, lat))
end

df.geometry = [parse_point(str) for str in df.geometry]
home = Point(-122.30947, 47.4489)



# Create a wide figure: map on the left, legend on the right
f = Figure(size = (1200, 600))
ga = GeoAxis(f[1, 1], dest = conus_crs)
hidedecorations!(ga)
Label(f[0, 1], "Seattle Mariners 2025 Road Trips", fontsize = 20)
Label(f[2, 1], "Source: https://www.baseball-reference.com/teams/SEA/2025-schedule-scores.shtml", fontsize = 9, halign=:right)

# Plot map and points as before
poly!(ga, geo.geometry, color = :white, strokecolor = :black, strokewidth = 0.25)
scatter!(ga, df.geometry, color = :white, strokecolor = :black, strokewidth = 0.5)
scatter!(ga, home, color = :red)

# Draw all lines in black, with appropriate linestyles and string labels for legend
for trip_id in unique(df.trip)
    trip_rows = filter(row -> row.trip == trip_id, eachrow(df))
    n = length(trip_rows)
    if n == 1
        lines!(ga, [home, trip_rows[1].geometry], color=:black, linewidth=1, linestyle=:solid, label="Outbound (home to first destination)")
        lines!(ga, [trip_rows[1].geometry, home], color=:black, linewidth=1, linestyle=:dash, label="Return (last destination to home)")
    else
        lines!(ga, [home, trip_rows[1].geometry], color=:black, linewidth=1, linestyle=:solid, label="Outbound (home to first destination)")
        for j in 1:(n-1)
            lines!(ga, [trip_rows[j].geometry, trip_rows[j+1].geometry], color=:black, linewidth=1, linestyle=:dot, label="Between destinations")
        end
        lines!(ga, [trip_rows[end].geometry, home], color=:black, linewidth=1, linestyle=:dash, label="Return (last destination to home)")
    end
end

# Add a clean, automatic legend to the map axis
# Add the legend to a dedicated axis
# Only the Legend in the right column, no Axis
Legend(f[1, 2], handles, labels, framevisible=false, bgcolor=:transparent)

colsize!(f.layout, 1, Relative(0.8))
colsize!(f.layout, 2, Relative(0.2))
display(f)

# Collect handles and labels for the legend
handles = [
    lines!(ga, [NaN, NaN], color=:black, linewidth=1, linestyle=:solid),
    lines!(ga, [NaN, NaN], color=:black, linewidth=1, linestyle=:dot),
    lines!(ga, [NaN, NaN], color=:black, linewidth=1, linestyle=:dash)
]
labels = [
    "Outbound (home to first destination)",
    "Between destinations",
    "Return (last destination to home)"
]

Legend(f[1, 2], handles, labels, framevisible=false)
display(f)

using Markdown
import Markdown: MD, Paragraph, Header, Italic, Bold, LineBreak, plain, term, html,
                             Table, Code, LaTeX
   ## Simple function plotter

alpha = ___(3.0) 

[[[Calculate]]]

```julia output=markdown 
println("## Results")
```

```julia
f(x, k) = 20*sin(k * x) ./ x
x = linspace(-5.,5,500)
plot(x, f(x, float(alpha)))
```                          