using CairoMakie, GeoMakie, PrettyTables

# Basic figure creation
f = Figure(size = (800, 600)) # default is white background
f = Figure(size = (800, 600), backgroundcolor = :lightgray)

# Elements positioned using array-like indexing
ax = Axis(f[1, 1])           # Row 1, Column 1
legend = Legend(f[1, 2], ax) # Row 1, Column 2

df = get_counties_geom()
df = subset(df, :statefp => ByRow(x -> x in VALID_STATEFPS))
conus = VALID_STATEFPS 
conus = setdiff(conus, ["02","15"])
df = subset(df, :statefp => ByRow(x -> x in conus))
total_counties = size(df, 1)
trauma_counties = sum(df.is_trauma_center)
nearby_counties = sum(df.nearby)
other_counties = total_counties - trauma_counties - nearby_counties
total_counties = with_commas(total_counties)
trauma_counties = with_commas(trauma_counties)
nearby_counties = with_commas(nearby_counties)
other_counties = with_commas(other_counties)
annot = DataFrame(t = total_counties, tc = trauma_counties, n = nearby_counties, o = other_counties)
table_string =     pretty_table(annot, 
header = ["Total Counties", "Trauma Centers", "Nearby Counties", "Other Counties"],
data = [total_counties trauma_counties nearby_counties other_counties])
# Capture PrettyTables output as a string
io = IOBuffer()
pretty_table(io, data, header=header, backend = Val(:text),
alignment = [:l, :l, :l, :l],
hlines = :none,
vlines = :none)
table_str = String(take!(io))

table_string = right_align_table_data(table_string)
f = Figure(size = (1000, 700))

# Main map in primary position

ga = GeoAxis(f[1, 1:2];
dest               = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
aspect             = DataAspect(),
xgridvisible       = false, ygridvisible = false,
xticksvisible      = false, yticksvisible = false,
xticklabelsvisible = false, yticklabelsvisible = false,
)

poly!(ga, df.geom, color=colores, strokecolor=:white, strokewidth=0.5)

# Legend to the right
legend = Legend(f[1, 3],
    [PolyElement(color=trauma_center_color, strokecolor=:black),
     PolyElement(color=nearby_color, strokecolor=:black),
     PolyElement(color=other_color, strokecolor=:black)],
    ["Trauma Centers", "Within 50 Miles", "Other Counties"],
    "County Categories"
)

# Title spanning full width
Label(f[0, :], "US Counties: Level 1 Trauma Centers and Nearby Areas"  , fontsize = 20)

# Caption below
Label(f[3, 3], "Source: https://en.wikipedia.org/wiki/List_of_trauma_centers_in_the_United_States", fontsize = 10)

# annotations
Label(f[2, 3], table_str; font="DejaVu Sans Mono", fontsize=24, halign=:left, valign=:top)
f[2, 1] = Label(f, "Trauma Center Statistics", fontsize=32)

display(f)

