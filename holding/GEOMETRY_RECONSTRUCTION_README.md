# Geometry Reconstruction Solution

This solution provides robust geometry reconstruction functions that work with iGeometry types and handle the "PointTrait leaf" error you encountered with `GeometryOps.reconstruct`.

## Problem

The `GeometryOps.reconstruct` function can fail with errors like:
```
Nothing found but reached a PointTrait leaf
```

This happens when the function encounters a point geometry when it expects a more complex geometry type.

## Solution

The solution provides two approaches:

1. **GeoInterface Approach** (Recommended - Simpler)
2. **ArchGDAL Approach** (Alternative - More powerful)

## Files

- `geometry_reconstruction.jl` - Main functions for geometry reconstruction
- `example_geometry_usage.jl` - Examples showing how to use the functions
- `GEOMETRY_RECONSTRUCTION_README.md` - This documentation

## Main Functions

### `affine_transform_geometry(geom, scale_x, scale_y, translate_x, translate_y; use_archgdal=false)`

Apply affine transformation (scale and translate) to geometry.

**Parameters:**
- `geom`: Geometry object to transform
- `scale_x`, `scale_y`: Scale factors for X and Y axes
- `translate_x`, `translate_y`: Translation values for X and Y axes
- `use_archgdal`: Whether to use ArchGDAL approach (default: false)

**Returns:** Transformed geometry object

### `transform_and_reconstruct(geom, transform_func; use_archgdal=false)`

Apply custom transformation function to geometry.

**Parameters:**
- `geom`: Geometry object to transform
- `transform_func`: Function that takes coordinates and returns transformed coordinates
- `use_archgdal`: Whether to use ArchGDAL approach (default: false)

**Returns:** Transformed geometry object

## Usage Examples

### Basic Affine Transformation

```julia
using GeometryBasics
using GeoInterface

# Create a polygon
coords = [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]]]
polygon = Polygon(coords)

# Scale by 2x in X, 3x in Y, translate by (10, 20)
transformed = affine_transform_geometry(polygon, 2.0, 3.0, 10.0, 20.0)
```

### Custom Transformation

```julia
# Define custom transformation (e.g., rotate 90 degrees)
function rotate_90_degrees(coord)
    x, y = coord[1], coord[2]
    return [-y, x]
end

# Apply custom transformation
rotated = transform_and_reconstruct(polygon, rotate_90_degrees)
```

### Working with DataFrames

```julia
using DataFrames

# Apply transformation to all geometries in a DataFrame
df.transformed_geom = map(df.geom) do geom
    affine_transform_geometry(geom, 0.5, 0.5, 100.0, 100.0)
end
```

### Using ArchGDAL Approach

```julia
using ArchGDAL

# Convert to ArchGDAL geometry and transform
ag_geom = ArchGDAL.createpolygon(coords)
transformed_ag = affine_transform_geometry(ag_geom, 2.0, 2.0, 0.0, 0.0, use_archgdal=true)
```

## Integration with Your Existing Code

### For Alaska/Hawaii Transformations

Based on your existing code in `affines.jl`, you can now use:

```julia
# Instead of the commented-out transform_geometry function
df.virtual_geom = map(eachrow(df)) do row
    if row.statefp == "02"  # Alaska
        affine_transform_geometry(row.geom, 0.25, 0.25, -8000000, 1750000)
    elseif row.statefp == "15"  # Hawaii
        affine_transform_geometry(row.geom, 1.0, 1.0, -1250000, -45000)
    else
        row.geom  # No transformation for CONUS
    end
end
```

### For Trauma Center Analysis

In your trauma query code, you can transform geometries:

```julia
# Transform geometries for visualization
trauma.transformed_geom = map(trauma.geom) do geom
    if !ismissing(geom)
        affine_transform_geometry(geom, 1.0, 1.0, 0.0, 0.0)
    else
        missing
    end
end
```

## Error Handling

The functions handle various error cases gracefully:

- **Missing geometries**: Returns `missing`
- **Empty coordinates**: Returns `missing`
- **Unsupported geometry types**: Returns `missing` with warning
- **Transformation failures**: Returns `missing` with error message

## Testing

Run the test function to verify everything works:

```julia
include("geometry_reconstruction.jl")
test_geometry_reconstruction()
```

Or run the full example:

```julia
include("example_geometry_usage.jl")
```

## Advantages

1. **Robust**: Handles the PointTrait error you encountered
2. **Flexible**: Supports both GeoInterface and ArchGDAL approaches
3. **Safe**: Graceful error handling for edge cases
4. **Compatible**: Works with your existing iGeometry types
5. **Simple**: Easy-to-use functions for common transformations

## When to Use Each Approach

### Use GeoInterface (default) when:
- Working with GeometryBasics types
- Need simple transformations
- Want faster processing
- Working with standard geometry types

### Use ArchGDAL when:
- Working with complex spatial operations
- Need advanced GDAL functionality
- Working with various coordinate systems
- Need to handle many different geometry formats

## Troubleshooting

If you still encounter issues:

1. **Check geometry type**: Use `GeoInterface.geomtrait(geom)` to see the geometry type
2. **Verify coordinates**: Use `GeoInterface.coordinates(geom)` to check coordinate structure
3. **Try ArchGDAL**: Switch to `use_archgdal=true` if GeoInterface fails
4. **Check for missing values**: Ensure geometries aren't `missing` before transformation

The solution should handle the "PointTrait leaf" error and provide a robust way to work with your iGeometry types. 