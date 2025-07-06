using Pkg; Pkg.activate()

# Include the geometry reconstruction functions
include("geometry_reconstruction.jl")

# Include your existing functions
include("get_counties_geom.jl")
include("src/constants.jl")

"""
    create_ak_hi_insets(df; alaska_scale=0.25, hawaii_scale=1.0)

Create Alaska and Hawaii insets by applying affine transformations to county geometries.

# Arguments
- `df`: DataFrame with county geometries (must have :geom and :statefp columns)
- `alaska_scale`: Scale factor for Alaska (default: 0.25 for 1/4 scale)
- `hawaii_scale`: Scale factor for Hawaii (default: 1.0 for full scale)

# Returns
- DataFrame with additional :inset_geom column containing transformed geometries
"""
function create_ak_hi_insets(df; alaska_scale=0.25, hawaii_scale=1.0)
    # Create a copy to avoid modifying the original
    result_df = copy(df)
    
    # Add inset geometry column
    result_df.inset_geom = similar(df.geom)
    
    # Apply transformations based on state
    for (i, row) in enumerate(eachrow(result_df))
        if row.statefp == "02"  # Alaska
            # Alaska transformation: scale down and move to bottom-left
            # These coordinates are in the projected coordinate system (EPSG:5070)
            result_df.inset_geom[i] = affine_transform_geometry(
                row.geom, 
                alaska_scale,    # scale_x
                alaska_scale,    # scale_y  
                -8000000,        # translate_x (move west)
                1750000,         # translate_y (move south)
                use_archgdal=false
            )
        elseif row.statefp == "15"  # Hawaii
            # Hawaii transformation: keep scale, move to bottom-right
            result_df.inset_geom[i] = affine_transform_geometry(
                row.geom,
                hawaii_scale,    # scale_x
                hawaii_scale,    # scale_y
                -1250000,        # translate_x (move west)
                -45000,          # translate_y (move south)
                use_archgdal=false
            )
        else
            # CONUS states: no transformation needed
            result_df.inset_geom[i] = row.geom
        end
    end
    
    return result_df
end

"""
    plot_ak_hi_insets(df; title="US Counties with Alaska/Hawaii Insets")

Create a plot showing CONUS counties with Alaska and Hawaii insets.

# Arguments
- `df`: DataFrame with :inset_geom column (output from create_ak_hi_insets)
- `title`: Plot title
"""
function plot_ak_hi_insets(df; title="US Counties with Alaska/Hawaii Insets")
    using CairoMakie
    using ColorSchemes
    
    # Create figure
    fig = Figure(resolution=(1200, 800))
    ax = Axis(fig[1, 1], 
              title=title,
              xticksvisible=false, 
              yticksvisible=false,
              xticklabelsvisible=false, 
              yticklabelsvisible=false)
    
    # Plot each county with its inset geometry
    for (i, row) in enumerate(eachrow(df))
        if !ismissing(row.inset_geom) && GeoInterface.isgeometry(row.inset_geom)
            # Get coordinates
            coords = GeoInterface.coordinates(row.inset_geom)
            if !isempty(coords)
                # Handle different geometry types
                if GeoInterface.geomtrait(row.inset_geom) isa GeoInterface.PolygonTrait
                    for ring in coords
                        if !isempty(ring)
                            poly!(ax, ring, color=:lightblue, strokecolor=:black, strokewidth=0.5)
                        end
                    end
                elseif GeoInterface.geomtrait(row.inset_geom) isa GeoInterface.MultiPolygonTrait
                    for polygon in coords
                        for ring in polygon
                            if !isempty(ring)
                                poly!(ax, ring, color=:lightblue, strokecolor=:black, strokewidth=0.5)
                            end
                        end
                    end
                end
            end
        end
    end
    
    # Add labels for insets
    text!(ax, -7500000, 2000000, text="Alaska", fontsize=16, color=:red)
    text!(ax, -1200000, 50000, text="Hawaii", fontsize=16, color=:red)
    
    return fig
end

# Main execution
println("Loading county geometries...")
df = get_counties_geom()

# Remove overseas territories (keep only CONUS + AK + HI)
println("Filtering to CONUS + Alaska + Hawaii...")
df = subset(df, :statefp => ByRow(x -> x in VALID_STATEFPS))

println("Creating Alaska/Hawaii insets...")
df_with_insets = create_ak_hi_insets(df)

# Print summary
ak_count = count(x -> x == "02", df_with_insets.statefp)
hi_count = count(x -> x == "15", df_with_insets.statefp)
conus_count = nrow(df_with_insets) - ak_count - hi_count

println("Summary:")
println("- CONUS counties: $conus_count")
println("- Alaska counties: $ak_count") 
println("- Hawaii counties: $hi_count")
println("- Total counties: $(nrow(df_with_insets))")

# Check if transformations worked
ak_transformed = count(x -> !ismissing(x) && x != df.geom[df.statefp .== "02"], df_with_insets.inset_geom[df_with_insets.statefp .== "02"])
hi_transformed = count(x -> !ismissing(x) && x != df.geom[df.statefp .== "15"], df_with_insets.inset_geom[df_with_insets.statefp .== "15"])

println("Transformations applied:")
println("- Alaska counties transformed: $ak_transformed/$ak_count")
println("- Hawaii counties transformed: $hi_transformed/$hi_count")

# Create the plot
println("Creating plot...")
fig = plot_ak_hi_insets(df_with_insets, title="US Counties with Alaska/Hawaii Insets")
display(fig)

println("Done! The plot shows CONUS counties with Alaska and Hawaii insets.")
println("Alaska is scaled to 1/4 size and positioned in the bottom-left.")
println("Hawaii is full size and positioned in the bottom-right.") 