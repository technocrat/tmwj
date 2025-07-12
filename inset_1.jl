#=
# Inset map of the USA

This example shows how to create an inset map of the USA, that preserves areas as best as possible.

This example is based on https://geocompx.github.io/geocompkg/articles/us-map.html

=#

using GeoMakie, CairoMakie
import GeoDataFrames
import GeometryOps as GO, GeoInterface as GI, GeoFormatTypes as GFT

#=
# Data preparation

The first step is to decide on the best projection for each individual inset. 
For this case, we decided to use equal area projections for the maps of the 
contiguous 48 states, Hawaii, and Alaska. 
While the dataset of Hawaii and Alaska already have this type of projections, 
we still need to reproject the `us_states` object to US National Atlas Equal Area:
=#

# CRS strings
conus_crs = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
ak_crs = "+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
hi_crs = "+proj=aea +lat_1=8 +lat_2=18 +lat_0=13 +lon_0=-157 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
# VALID_STATEFPS
include("src/constants.jl")
all_states = GeoDataFrames.read("data/cb_2018_us_state_500k.shp")
all_states = subset(all_states, :STATEFP => ByRow(x -> x ∈ VALID_STATEFPS))
conus = subset(all_states, :STATEFP => ByRow(x -> x ∉ ("02", "15")))
ak = subset(all_states, :STATEFP => ByRow(x -> x == "02"))
hi = subset(all_states, :STATEFP => ByRow(x -> x == "15"))


#=
# Ratio calculation
The second step is to calculate scale relations between the main map 
(the contiguous 48 states) and Hawaii, and between the main map and Alaska. 
To do so we can calculate areas of the bounding box of each object:
=#

conus_range = GI.extent(conus.geometry |> GI.GeometryCollection).Y[2] - GI.extent(conus.geometry |> GI.GeometryCollection).Y[1]
ak_range = GI.extent(ak.geometry |> GI.GeometryCollection).Y[2] - GI.extent(ak.geometry |> GI.GeometryCollection).Y[1]
hi_range = GI.extent(hi.geometry |> GI.GeometryCollection).Y[2] - GI.extent(hi.geometry |> GI.GeometryCollection).Y[1]

# Next, we can calculate the ratio between their areas:

us_states_hawaii_ratio = hawaii_range / us_states_range
us_states_alaska_ratio = alaska_range / us_states_range
(; us_states_hawaii_ratio, us_states_alaska_ratio) # hide

#=
# Map creation

We can now create the inset maps.

Here, we diverge from the original example, since Makie.jl does not 
support creating axes independently of a Figure easily.

=#

# First, we instantiate the figure and the axes:
    fig = Figure(size = (1200, 800))
## Alaska takes the top row
ax_alaska = GeoAxis(fig[1, 1]; dest = ak_crs, tellheight = false, tellwidth = false,
aspect             = DataAspect(),
xgridvisible       = false, ygridvisible = false,
xticksvisible      = false, yticksvisible = false,
xticklabelsvisible = false, yticklabelsvisible = false)

poly!(ax_alaska, ak.geometry, color=:white, strokecolor=:black, strokewidth=0.5)
## The contiguous 48 states take the bottom row

ax_conus = GeoAxis(fig[2, 1];  dest = conus_crs, tellheight = false, tellwidth = false,
aspect             = DataAspect(),
xgridvisible       = false, ygridvisible = false,
xticksvisible      = false, yticksvisible = false,
xticklabelsvisible = false, yticklabelsvisible = false)

poly!(ax_conus, conus.geometry, color=:white, strokecolor=:black, strokewidth=0.5)
## Hawaii will be an inset, so we don't assign it a grid cell yet:
ax_hawaii = GeoAxis(fig; source = dest = hi_crs, tellheight = false, tellwidth = false,aspect             = DataAspect(),
xgridvisible       = false, ygridvisible = false,
xticksvisible      = false, yticksvisible = false,
xticklabelsvisible = false, yticklabelsvisible = false)
poly!(ax_hawaii, hi.geometry, color = :lightgray, strokewidth = 0.75, strokecolor = :darkgray)

hidedecorations!(ax_alaska)
hidedecorations!(ax_conus)
hidedecorations!(ax_hawaii)
fig
# Now, we can set the row heights:
rowsize!(fig.layout, 1, Auto(false, us_states_alaska_ratio))
rowsize!(fig.layout, 2, Auto(false, 1))
rowgap!(fig.layout, 0)
fig

# Now, we move Hawaii to its rightful place:
fig[2, 1] = ax_hawaii
ax_hawaii.valign[] = 0.07
ax_hawaii.halign[] = 0
ax_hawaii.height[] = Auto(false, us_states_hawaii_ratio / (us_states_alaska_ratio + 1))
#=

=#