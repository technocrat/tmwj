using CairoMakie, GeoInterfaceMakie
using GeoDataFrames         # for GDF.read
using GeometryOps           # for transform
using StaticArrays          # for convenient SVector
using ArchGDAL
using GeometryOps
import GeometryOps: transform
import GeoInterface: geometry
using GeoInterface, GeometryOps, StaticArrays
using LibGEOS
using GeometryBasics
using GeoMakie

using GeoDataFrames       # gives you gdf.geometry :: Vector{IGeometry}
using GeoInterface        # for geometry(::IGeometry) → GeometryBasics
using GeometryOps         # exports transform(f, geom)
using StaticArrays        # for SVector

# 1. Read any GDAL-supported file (shapefile, geopackage, GeoJSON…)
gdf = GeoDataFrames.read("data/cb_2023_us_county_500k.shp")   # df.geometry is a Vector{IGeometry} :contentReference[oaicite:1]{index=1}

# 2) Build the per-feature affine functions
#    (Alaska scaled & shifted, Hawaii shifted, else identity)
transforms = [
    row.STATEFP == "02" ? (p-> p .* 0.25 .+ SVector(-8e6,  1.75e6)) :
    row.STATEFP == "15" ? (p-> p       .+ SVector(-1.25e6, -4.5e4)) :
                            identity
    for row in eachrow(gdf)
]

# 3) Convert ArchGDAL.IGeometry → LibGEOS geometry
geos_geoms = GeoInterface.convert.(Ref(LibGEOS), gdf.geometry)             # :contentReference[oaicite:1]{index=1}

# 4) Convert LibGEOS → GeometryBasics geometry
basic_geoms = GeoInterface.convert.(Ref(GeometryBasics), geos_geoms)        # :contentReference[oaicite:2]{index=2}

# 5) Apply your affine transforms
inset_geoms = GeometryOps.transform.(transforms, basic_geoms)               # :contentReference[oaicite:3]{index=3}

# 6) Plot in one shot
fig = Figure(size=(1200,800))
ax  = GeoAxis(fig[1,1]; title="US Counties w/ AK & HI Insets",
               xticksvisible=false, yticksvisible=false)
poly!(ax, inset_geoms; color=:white, strokecolor=:black, strokewidth=0.2)

fig