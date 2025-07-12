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
ak = subset(df, :statefp => ByRow(x -> x == "02"))

# Debug Alaska data
println("Alaska data debug:")
println("Number of Alaska counties: ", nrow(ak))
if nrow(ak) > 0
    println("Alaska columns: ", names(ak))
    println("First Alaska county: ", ak[1, :geoid])
    println("Alaska geometry type: ", typeof(ak.geom))
    println("First Alaska geometry: ", ak.geom[1])
else
    println("No Alaska data found!")
end

# Debug Alaska geometry bounds
println("Checking Alaska geometry bounds...")
if nrow(ak) > 0
    # Get bounds of first Alaska geometry
    first_geom = ak.geom[1]
    println("First Alaska geometry type: ", ArchGDAL.getgeomtype(first_geom))
    
    # Try to get bounds using ArchGDAL
    try
        bounds = ArchGDAL.bounds(first_geom)
        println("Alaska bounds: ", bounds)
    catch e
        println("Could not get bounds: ", e)
    end
end

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

# Alaska Albers projection for inset
ak_proj = "+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +datum=WGS84 +units=m +no_defs"

# Compute tight bounding box for all Alaska geometries
using Statistics

println("Computing Alaska bounding box...")
if nrow(ak) > 0
    min_lon = Inf
    max_lon = -Inf
    min_lat = Inf
    max_lat = -Inf
    valid_bounds_found = false
    for geom in ak.geom
        try
            b = ArchGDAL.bounds(geom)
            if all(isfinite, b)
                min_lon = min(min_lon, b[1])
                max_lon = max(max_lon, b[2])
                min_lat = min(min_lat, b[3])
                max_lat = max(max_lat, b[4])
                valid_bounds_found = true
            else
                println("Skipping geometry with non-finite bounds: ", b)
            end
        catch e
            println("Could not get bounds for a geometry: ", e)
        end
    end
    if valid_bounds_found
        # Add a small margin
        margin_lon = (max_lon - min_lon) * 0.05
        margin_lat = (max_lat - min_lat) * 0.05
        ak_limits = (min_lon - margin_lon, max_lon + margin_lon, min_lat - margin_lat, max_lat + margin_lat)
        println("Alaska axis limits: ", ak_limits)
    else
        ak_limits = (-180, -130, 50, 75)
        println("No valid bounds found for Alaska, using default limits: ", ak_limits)
    end
else
    ak_limits = (-180, -130, 50, 75)
end

# Override the Alaska inset axis limits to focus on the main landmass
# Focus on the main landmass, ignore most Aleutians
ak_limits = (-170, -140, 54, 72)

ax_inset = GeoAxis(
    f[1, 4],
    dest="EPSG:4326",
    title="AK/HI (not to scale)",
    xgridvisible=false, ygridvisible=false,
    xticksvisible=false, yticksvisible=false,
    xticklabelsvisible=false, yticklabelsvisible=false,
    width=Relative(0.22),   # make inset larger
    height=Relative(0.22),
    limits=ak_limits,
    aspect=:auto,           # allow non-square aspect
)

# Debug inset plotting
println("Inset plotting debug:")
println("Number of Alaska counties for plotting: ", nrow(ak))
println("Alaska geometry vector length: ", length(ak.geom))

AK_colores = [ak.is_trauma_center[i] == true ? trauma_center_color : 
    ak.nearby[i] == true ? nearby_color : other_color 
    for i in eachindex(ak.is_trauma_center)]

println("Alaska colors vector length: ", length(AK_colores))

# Try plotting with error handling
try
    poly!(ax_inset, ak.geom, color=AK_colores, strokecolor=:white, strokewidth=0.5)
    println("Alaska inset plotted successfully")
catch e
    println("Error plotting Alaska inset: ", e)
    # Try plotting without colors first
    try
        poly!(ax_inset, ak.geom, color=:gray, strokecolor=:white, strokewidth=0.5)
        println("Alaska inset plotted with gray color")
    catch e2
        println("Error plotting Alaska inset even with gray: ", e2)
    end
end

display(f)
