using Pkg; Pkg.activate(@__DIR__)
using CairoMakie, ColorSchemes, GeoDataFrames,  GeoMakie
include("src/utils.jl")
include("src/constants.jl")
include("trauma_query_libpq.jl")

# blue for more, reddish for less
BuRd_6 = reverse(colorschemes[:RdBu_6])

df = create_trauma_dataframe(50)      
df = subset(df, :statefp => ByRow(x -> x in VALID_STATEFPS))
conus = VALID_STATEFPS 
conus = setdiff(conus, ["02","15"])
df = subset(df, :statefp => ByRow(x -> x in conus))
df = unique(df, :geoid)
total_counties = size(df, 1)
trauma_counties = sum(df.is_trauma_center)
nearby_counties = sum(df.nearby)
other_counties = total_counties - trauma_counties - nearby_counties
total_counties = lpad(with_commas(total_counties), 12)
trauma_counties = lpad(with_commas(trauma_counties), 12)
nearby_counties = lpad(with_commas(nearby_counties), 12)
other_counties = lpad(with_commas(other_counties), 12)
served = subset(df, [:is_trauma_center, :nearby] => ByRow((tc, nb) -> tc || nb))
percentage_counties_served = percent(nrow(served) / nrow(df))
percentage_served_population = percent(Float64(sum(served.population) / sum(df.population)))
total_population = with_commas(sum(df.population))
served_population = with_commas(sum(served.population))
all_counties = with_commas(nrow(df))
served_counties = with_commas(nrow(served))

headers = ["Category", "Counties"]
rows = [["Trauma Center", trauma_counties], ["Nearby", nearby_counties], ["Other", other_counties], ["Total", total_counties]]
table_text = format_table_as_text(headers, rows)


squib = "Of the $all_counties counties in the continental United States, $served_counties have a Level 1 trauma center within 50 miles, or $percentage_counties_served of the counties. This represents $served_population of the total population, or $percentage_served_population. Alaska has no Level 1 trauma centers and relies on air ambulance services to transport patients to trauma centers in the lower 48 states. Hawaii has one Level 1 trauma center, in Honolulu, and relies on air ambulance services to transport patients from other islands."
squib = hard_wrap(squib, 60)

trauma_center_color = BuRd_6[1]
nearby_color = BuRd_6[2]
other_color = BuRd_6[4]

# Create color vector based on trauma center status
colores = [df.is_trauma_center[i] == true ? trauma_center_color : 
    df.nearby[i] == true ? nearby_color : other_color 
    for i in eachindex(df.is_trauma_center)]


f = Figure(size = (1000, 700))

# Main map in primary position

ga = GeoAxis(f[1, 1:3];
dest               = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
aspect             = DataAspect(),
xgridvisible       = false, ygridvisible = false,
xticksvisible      = false, yticksvisible = false,
xticklabelsvisible = false, yticklabelsvisible = false,
)
poly!(ga, df.geom, color=colores, strokecolor=:white, strokewidth=0.5)

# Scale bar (50 miles interval) 
scale_length_m = 80467.2  # 50 miles in meters
# Example: lower left of the conterminous US bounding box (adjust as needed)
x0, y0 = -2.2e6, -1.6e6
x1 = x0 + scale_length_m
lines!(ga, [x0, x1], [y0, y0], color=:black, linewidth=3)
text!(ga, "50 mi", position = ((x0 + x1)/2, y0 - 5e4), align = (:center, :top), fontsize=12)

# Legend to the right
legend = Legend(f[2, 3],
    [PolyElement(color=trauma_center_color, strokecolor=:black),
     PolyElement(color=nearby_color, strokecolor=:black),
     PolyElement(color=other_color, strokecolor=:black)],
    ["Trauma Centers", "Within 50 Miles", "Other Counties"],
    "County Categories", halign=:right, fontsize=10
)

# Title spanning full width
Label(f[0, :], "US Counties: Level 1 Trauma Centers and Nearby Areas"  , fontsize = 20)

# Caption below
Label(f[3, 3], "Source: Richard Careaga from https://en.wikipedia.org/wiki/List_of_trauma_centers_in_the_United_States", fontsize = 10, halign=:right)

# Summary table
Label(f[2, 2], table_text; font="DejaVu Sans Mono", fontsize=10, halign=:left, valign=:top)

# Summary text
Label(f[2, 1], squib; fontsize=10, halign=:left, valign=:top, justification=:left)

# North arrow with rotation capability
north_arrow = "\u21E7\nN"
text!(f.scene, north_arrow, 
      position=(0.85, 0.6),
      # rotation=π/6,          # 30 degrees (uncomment to rotate)
      space=:relative,
      align=(:left, :top), 
      fontsize=36, color=:black)

# Scale bar positioned under the north arrow (in relative coordinates)
# Calculate scale bar length based on actual map scale
map_width = 4.4e6  # approximate width of CONUS in meters
scale_bar_length = (80467.2 / map_width) * 0.8  # 50 miles as fraction of map width
scale_bar_x = 0.85
scale_bar_y = 0.45
lines!(f.scene, [scale_bar_x - scale_bar_length/2, scale_bar_x + scale_bar_length/2], 
       [scale_bar_y, scale_bar_y], 
       space=:relative, color=:black, linewidth=3)

# Scale bar label positioned under the scale bar
text!(f.scene, "50 mi", 
      position=(scale_bar_x, scale_bar_y - 0.02),  # positioned under the scale bar
      space=:relative,
      align=(:center, :top), 
      fontsize=14, color=:black)


display(f)
