using Pkg; Pkg.activate()

# Include the geometry reconstruction functions
include("geometry_reconstruction.jl")

# Example 1: Using with GeoInterface (simpler approach)
println("=== Example 1: GeoInterface Approach ===")

# Create a simple polygon (similar to what you might get from your data)
using GeometryBasics
test_coords = [Point2f(0.0, 0.0), Point2f(1.0, 0.0), Point2f(1.0, 1.0), Point2f(0.0, 1.0), Point2f(0.0, 0.0)]
original_polygon = Polygon(test_coords)

println("Original polygon: ", GeoInterface.coordinates(original_polygon))

# Apply affine transformation (scale and translate)
transformed_polygon = affine_transform_geometry(
    original_polygon, 
    2.0,  # scale_x
    3.0,  # scale_y
    10.0, # translate_x
    20.0, # translate_y
    use_archgdal=false  # Use GeoInterface
)

if !ismissing(transformed_polygon)
    println("Transformed polygon: ", GeoInterface.coordinates(transformed_polygon))
else
    println("Transformation failed")
end

# Example 2: Using with ArchGDAL (alternative approach)
println("\n=== Example 2: ArchGDAL Approach ===")

using ArchGDAL

# Create ArchGDAL geometry
ag_coords = [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]]]
ag_geom = ArchGDAL.createpolygon(ag_coords)
println("Original ArchGDAL geometry: ", extract_archgdal_coordinates(ag_geom))

# Apply transformation using ArchGDAL
transformed_ag = affine_transform_geometry(
    ag_geom,
    0.5,  # scale_x
    0.5,  # scale_y
    5.0,  # translate_x
    5.0,  # translate_y
    use_archgdal=true  # Use ArchGDAL
)

if !ismissing(transformed_ag)
    println("Transformed ArchGDAL geometry: ", extract_archgdal_coordinates(transformed_ag))
else
    println("ArchGDAL transformation failed")
end

# Example 3: Custom transformation function
println("\n=== Example 3: Custom Transformation ===")

# Define a custom transformation (e.g., rotate by 90 degrees)
function rotate_90_degrees(coord)
    x, y = coord[1], coord[2]
    return [-y, x]  # 90-degree rotation
end

# Apply custom transformation
rotated_polygon = transform_and_reconstruct(
    original_polygon,
    rotate_90_degrees,
    use_archgdal=false
)

if !ismissing(rotated_polygon)
    println("Rotated polygon: ", GeoInterface.coordinates(rotated_polygon))
else
    println("Rotation failed")
end

# Example 4: Working with your existing data structure
println("\n=== Example 4: Working with DataFrame Geometries ===")

# Simulate your existing DataFrame with geometries
using DataFrames

# Create sample data similar to your county geometries
sample_data = DataFrame(
    geoid = ["01001", "01003", "01005"],
    name = ["Autauga", "Baldwin", "Barbour"],
    geom = [
        Polygon([Point2f(0.0, 0.0), Point2f(1.0, 0.0), Point2f(1.0, 1.0), Point2f(0.0, 1.0), Point2f(0.0, 0.0)]),
        Polygon([Point2f(1.0, 1.0), Point2f(2.0, 1.0), Point2f(2.0, 2.0), Point2f(1.0, 2.0), Point2f(1.0, 1.0)]),
        Polygon([Point2f(2.0, 2.0), Point2f(3.0, 2.0), Point2f(3.0, 3.0), Point2f(2.0, 3.0), Point2f(2.0, 2.0)])
    ]
)

println("Original sample data:")
for (i, row) in enumerate(eachrow(sample_data))
    println("  Row $i ($(row.name)): ", GeoInterface.coordinates(row.geom))
end

# Apply transformation to all geometries
sample_data.transformed_geom = map(sample_data.geom) do geom
    affine_transform_geometry(geom, 0.5, 0.5, 100.0, 100.0, use_archgdal=false)
end

println("\nTransformed sample data:")
for (i, row) in enumerate(eachrow(sample_data))
    if !ismissing(row.transformed_geom)
        println("  Row $i ($(row.name)): ", GeoInterface.coordinates(row.transformed_geom))
    else
        println("  Row $i ($(row.name)): Transformation failed")
    end
end

# Example 5: Error handling demonstration
println("\n=== Example 5: Error Handling ===")

# Test with invalid geometry
try
    invalid_result = affine_transform_geometry(missing, 1.0, 1.0, 0.0, 0.0, use_archgdal=false)
    println("Handled missing geometry gracefully")
catch e
    println("Error with missing geometry: $e")
end

# Test with empty coordinates
empty_polygon = Polygon(Point2f[])
try
    empty_result = affine_transform_geometry(empty_polygon, 1.0, 1.0, 0.0, 0.0, use_archgdal=false)
    println("Handled empty geometry gracefully")
catch e
    println("Error with empty geometry: $e")
end

println("\n=== All examples completed! ===") 