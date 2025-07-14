using Pkg; Pkg.activate()

using DataFrames
using LibPQ
using ArchGDAL
include("src/constants.jl")
conn = LibPQ.Connection("host=localhost dbname=tiger")
query = """
WITH projected AS (
  SELECT
    geoid,
    statefp,
    CASE
      WHEN statefp = '02' THEN ST_Transform(geom, 3338)
      WHEN statefp = '15' THEN ST_Transform(geom, 102007)
      ELSE ST_Transform(geom, 5070)
    END AS proj_geom
  FROM census.counties
),
transformed AS (
  SELECT
    geoid,
    statefp,
    CASE
      WHEN statefp = '02' THEN
        ST_SetSRID(ST_TransScale(proj_geom, -8000000, 1750000, 0.25, 0.25), 5070)
      WHEN statefp = '15' THEN
        ST_SetSRID(ST_TransScale(proj_geom, -1250000, -45000, 1, 1), 5070)
      ELSE
        proj_geom
    END AS final_geom
  FROM projected
)
SELECT
  geoid,
  statefp,
  ST_AsBinary(final_geom) AS geom_wkb
FROM transformed;

"""
df = execute(conn, query) |> DataFrame
close(conn)
df.geom = ArchGDAL.fromWKB.(df.geom_wkb)

# Debug: Check what we have for Alaska and Hawaii
println("Total counties: ", nrow(df))
println("Alaska counties: ", count(x -> x == "02", df.statefp))
println("Hawaii counties: ", count(x -> x == "15", df.statefp))

# Check if geometries are valid
ak_hi_df = subset(df, :statefp => ByRow(x -> x in ["02", "15"]))
if nrow(ak_hi_df) > 0
    println("Alaska/Hawaii counties found:")
    for row in eachrow(ak_hi_df)
        println("  State: $(row.statefp), County: $(row.geoid)")
    end
    
    # Check coordinate bounds for transformed geometries
    println("\nCoordinate bounds for transformed geometries:")
    for statefp in ["02", "15"]
        state_df = subset(ak_hi_df, :statefp => ByRow(x -> x == statefp))
        if nrow(state_df) > 0
            println("State $(statefp):")
            for row in eachrow(state_df[1:min(3, nrow(state_df)), :])
                try
                    env = ArchGDAL.envelope(ArchGDAL.getgeom(row.geom, 0))
                    println("  County $(row.geoid): X=[", env.MinX, ", ", env.MaxX, "], Y=[", env.MinY, ", ", env.MaxY, "]")
                catch e
                    println("  County $(row.geoid): Error getting bounds - $(e)")
                end
            end
        end
    end
end

subset!(df, :statefp => ByRow(x -> x in VALID_STATEFPS))
select!(df, :geoid, :statefp, :geom)

# using GeoDataFrames
# gdf = GeoDataFrame(df)
# rename!(gdf, :geom => :geometry)
# GeoDataFrames.write("output.gpkg", gdf)
# fdg = GeoDataFrames.read("output.gpkg")