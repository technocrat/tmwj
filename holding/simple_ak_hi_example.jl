using Pkg; Pkg.activate()

# Include the geometry reconstruction functions
include("geometry_reconstruction.jl")

# Simple example showing the key concepts for AK/HI insets

"""
Key concepts for Alaska/Hawaii insets:

1. **Transform geometries BEFORE plotting** (not at plot time)
2. **Use projected coordinates** (EPSG:5070 for CONUS, EPSG:3338 for Alaska, EPSG:102007 for Hawaii)
3. **Apply affine transformations** (scale + translate)
4. **Plot everything in the same coordinate system**

The workflow is:
1. Load geometries in their native projections
2. Transform to a common projection (EPSG:5070)
3. Apply inset transformations (scale + translate)
4. Plot all geometries together
"""

# Example transformation parameters (in meters, EPSG:5070 coordinates)
alaska_params = (
    scale_x = 0.25,      # 1/4 scale
    scale_y = 0.25,      # 1/4 scale  
    translate_x = -8000000,  # Move west (negative = west)
    translate_y = 1750000    # Move south (positive = south)
)

hawaii_params = (
    scale_x = 1.0,       # Full scale
    scale_y = 1.0,       # Full scale
    translate_x = -1250000,  # Move west
    translate_y = -45000     # Move south
)

# Example usage with your existing data:
"""
# Load your county data
df = get_counties_geom()

# Apply transformations
df.inset_geom = map(eachrow(df)) do row
    if row.statefp == "02"  # Alaska
        affine_transform_geometry(
            row.geom, 
            alaska_params.scale_x,
            alaska_params.scale_y, 
            alaska_params.translate_x,
            alaska_params.translate_y,
            use_archgdal=false
        )
    elseif row.statefp == "15"  # Hawaii
        affine_transform_geometry(
            row.geom,
            hawaii_params.scale_x,
            hawaii_params.scale_y,
            hawaii_params.translate_x, 
            hawaii_params.translate_y,
            use_archgdal=false
        )
    else
        row.geom  # CONUS - no transformation
    end
end

# Then plot using the inset_geom column
# All geometries will be in the same coordinate system and properly positioned
"""

println("Key points for Alaska/Hawaii insets:")
println("1. Transform geometries BEFORE plotting (not at plot time)")
println("2. Use projected coordinates (EPSG:5070)")
println("3. Apply scale + translate transformations")
println("4. Plot everything together in the same coordinate system")
println()
println("Alaska parameters: scale=0.25, translate=(-8000000, 1750000)")
println("Hawaii parameters: scale=1.0, translate=(-1250000, -45000)")
println()
println("Run ak_hi_insets_example.jl for a complete working example!") 