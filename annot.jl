using CairoMakie, ColorSchemes, GeoMakie
include("src/constants.jl")
include("get_counties_geom.jl")
include("trauma_query_libpq.jl")
include("src/plot_with_legend.jl")
include("src/utils.jl")

# blue for more, red for less
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
total = lpad("Total",7)
trauma = lpad("Trauma", 7)
nearby = lpad("Nearby", 7)
other = lpad("Other",7)
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

# --- Scale bar (50 miles interval) ---
scale_length_m = 80467.2  # 50 miles in meters
# Example: lower left of the conterminous US bounding box (adjust as needed)
x0, y0 = -2.2e6, -1.6e6
x1 = x0 + scale_length_m
lines!(ga, [x0, x1], [y0, y0], color=:black, linewidth=3)
text!(ga, "50 mi", position = ((x0 + x1)/2, y0 - 5e4), align = (:center, :top), fontsize=12)

# --- North arrow ---
nx, ny = -2.1e6, 1.7e6  # Example: top left (adjust as needed)
arrows!(ga, [nx], [ny], [0], [1e5], arrowsize=0.2, color=:black)
text!(ga, "N", position = (nx, ny + 1.2e5), align = (:center, :bottom), fontsize=14)

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
Label(f[3, 3], "Source: https://en.wikipedia.org/wiki/List_of_trauma_centers_in_the_United_States", fontsize = 10, halign=:right)

# Summary table
Label(f[2, 2], table_text; font="DejaVu Sans Mono", fontsize=10, halign=:left, valign=:top)

# Summary text
Label(f[2, 1], squib; fontsize=10, halign=:left, valign=:top, justification=:left)

display(f)
