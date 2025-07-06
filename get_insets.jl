using Pkg; Pkg.activate()
using GeoInterface
using ArchGDAL
using GeometryBasics
using GeometryOps

"""
    safe_reconstruct_geointeface(geom, new_coords)

Safely reconstruct a geometry using GeoInterface approach.
This handles the case where GeometryOps.reconstruct fails with PointTrait errors.

# Arguments
- `geom`: Original geometry object
- `new_coords`: New coordinates to use for reconstruction

# Returns
- Reconstructed geometry object or missing if reconstruction fails
"""
function safe_reconstruct_geointeface(geom, new_coords)
    try
        # Get the geometry trait to understand the type
        trait = GeoInterface.geomtrait(geom)
        
        # Handle different geometry types
        if trait isa GeoInterface.PointTrait
            # For points, just return the first coordinate
            if !isempty(new_coords) && !isempty(new_coords[1])
                return Point(new_coords[1])
            else
                return missing
            end
            
        elseif trait isa GeoInterface.LineStringTrait
            # For line strings, create from coordinates
            if !isempty(new_coords) && !isempty(new_coords[1])
                return LineString(new_coords[1])
            else
                return missing
            end
            
        elseif trait isa GeoInterface.PolygonTrait
            # For polygons, create from ring coordinates
            if !isempty(new_coords)
                return Polygon(new_coords)
            else
                return missing
            end
            
        elseif trait isa GeoInterface.MultiPointTrait
            # For multi-points, create from point coordinates
            if !isempty(new_coords)
                points = [Point(coord) for coord in new_coords]
                return MultiPoint(points)
            else
                return missing
            end
            
        elseif trait isa GeoInterface.MultiLineStringTrait
            # For multi-line strings, create from line coordinates
            if !isempty(new_coords)
                lines = [LineString(line_coords) for line_coords in new_coords]
                return MultiLineString(lines)
            else
                return missing
            end
            
        elseif trait isa GeoInterface.MultiPolygonTrait
            # For multi-polygons, create from polygon coordinates
            if !isempty(new_coords)
                polygons = [Polygon(poly_coords) for poly_coords in new_coords]
                return MultiPolygon(polygons)
            else
                return missing
            end
            
        else
            # Try GeometryOps.reconstruct as fallback
            return GeometryOps.reconstruct(geom, new_coords)
        end
        
    catch e
        println("Warning: GeoInterface reconstruction failed: $e")
        return missing
    end
end

"""
    safe_reconstruct_archgdal(geom, new_coords)

Safely reconstruct a geometry using ArchGDAL approach.
This is an alternative when GeoInterface reconstruction fails.

# Arguments
- `geom`: Original ArchGDAL geometry object
- `new_coords`: New coordinates to use for reconstruction

# Returns
- Reconstructed ArchGDAL geometry object or missing if reconstruction fails
"""
function safe_reconstruct_archgdal(geom, new_coords)
    try
        # Get geometry type from ArchGDAL
        geom_type = ArchGDAL.getgeomtype(geom)
        
        # Convert coordinates to the format ArchGDAL expects
        if geom_type == ArchGDAL.wkbPoint
            if !isempty(new_coords) && !isempty(new_coords[1])
                return ArchGDAL.createpoint(new_coords[1])
            end
            
        elseif geom_type == ArchGDAL.wkbLineString
            if !isempty(new_coords) && !isempty(new_coords[1])
                return ArchGDAL.createlinestring(new_coords[1])
            end
            
        elseif geom_type == ArchGDAL.wkbPolygon
            if !isempty(new_coords)
                return ArchGDAL.createpolygon(new_coords)
            end
            
        elseif geom_type == ArchGDAL.wkbMultiPoint
            if !isempty(new_coords)
                points = [ArchGDAL.createpoint(coord) for coord in new_coords]
                return ArchGDAL.createmultipoint(points)
            end
            
        elseif geom_type == ArchGDAL.wkbMultiLineString
            if !isempty(new_coords)
                lines = [ArchGDAL.createlinestring(line_coords) for line_coords in new_coords]
                return ArchGDAL.createmultilinestring(lines)
            end
            
        elseif geom_type == ArchGDAL.wkbMultiPolygon
            if !isempty(new_coords)
                polygons = [ArchGDAL.createpolygon(poly_coords) for poly_coords in new_coords]
                return ArchGDAL.createmultipolygon(polygons)
            end
            
        else
            println("Warning: Unsupported geometry type: $geom_type")
            return missing
        end
        
        return missing
        
    catch e
        println("Warning: ArchGDAL reconstruction failed: $e")
        return missing
    end
end

"""
    transform_and_reconstruct(geom, transform_func; use_archgdal=false)

Transform geometry coordinates and reconstruct the geometry.
This is the main function that handles the transformation and reconstruction process.

# Arguments
- `geom`: Original geometry object
- `transform_func`: Function to transform coordinates (takes a coordinate and returns transformed coordinate)
- `use_archgdal`: Whether to use ArchGDAL approach (default: false, uses GeoInterface)

# Returns
- Transformed and reconstructed geometry object
"""
function transform_and_reconstruct(geom, transform_func; use_archgdal=false)
    try
        # Get original coordinates
        if use_archgdal
            # Use ArchGDAL to get coordinates
            coords = ArchGDAL.getcoord(geom)
        else
            # Use GeoInterface to get coordinates
            coords = GeoInterface.coordinates(geom)
        end
        
        # Transform coordinates
        new_coords = transform_coordinates(coords, transform_func)
        
        # Reconstruct geometry
        if use_archgdal
            return safe_reconstruct_archgdal(geom, new_coords)
        else
            return safe_reconstruct_geointeface(geom, new_coords)
        end
        
    catch e
        println("Error in transform_and_reconstruct: $e")
        return missing
    end
end

"""
    transform_coordinates(coords, transform_func)

Recursively transform coordinates using the provided transformation function.

# Arguments
- `coords`: Nested coordinate structure
- `transform_func`: Function to transform individual coordinates

# Returns
- Transformed coordinate structure
"""
function transform_coordinates(coords, transform_func)
    if isempty(coords)
        return coords
    end
    
    # Check if this is a coordinate (array of numbers)
    if all(x -> isa(x, Number), coords) && length(coords) >= 2
        return transform_func(coords)
    else
        # Recursively transform nested coordinates
        return [transform_coordinates(coord, transform_func) for coord in coords]
    end
end

"""
    affine_transform_geometry(geom, scale_x=1.0, scale_y=1.0, translate_x=0.0, translate_y=0.0; use_archgdal=false)

Apply affine transformation to geometry (scale and translate).

# Arguments
- `geom`: Geometry object to transform
- `scale_x`: X-axis scale factor
- `scale_y`: Y-axis scale factor  
- `translate_x`: X-axis translation
- `translate_y`: Y-axis translation
- `use_archgdal`: Whether to use ArchGDAL approach

# Returns
- Transformed geometry object
"""
function affine_transform_geometry(geom, scale_x=1.0, scale_y=1.0, translate_x=0.0, translate_y=0.0; use_archgdal=false)
    transform_func = coord -> [coord[1] * scale_x + translate_x, coord[2] * scale_y + translate_y]
    return transform_and_reconstruct(geom, transform_func, use_archgdal=use_archgdal)
end

# Example usage and testing functions
"""
    test_geometry_reconstruction()

Test the geometry reconstruction functions with sample data.
"""
function test_geometry_reconstruction()
    println("Testing geometry reconstruction functions...")
    
    # Create a simple polygon for testing
    coords = [[[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]]]
    test_polygon = Polygon(coords)
    
    println("Original polygon coordinates: ", GeoInterface.coordinates(test_polygon))
    
    # Test GeoInterface approach
    println("\nTesting GeoInterface approach...")
    transformed_gi = affine_transform_geometry(test_polygon, 2.0, 3.0, 10.0, 20.0, use_archgdal=false)
    if !ismissing(transformed_gi)
        println("GeoInterface transformed coordinates: ", GeoInterface.coordinates(transformed_gi))
    else
        println("GeoInterface transformation failed")
    end
    
    # Test ArchGDAL approach
    println("\nTesting ArchGDAL approach...")
    # Convert to ArchGDAL geometry
    ag_geom = ArchGDAL.createpolygon(coords)
    transformed_ag = affine_transform_geometry(ag_geom, 2.0, 3.0, 10.0, 20.0, use_archgdal=true)
    if !ismissing(transformed_ag)
        println("ArchGDAL transformed coordinates: ", ArchGDAL.getcoord(transformed_ag))
    else
        println("ArchGDAL transformation failed")
    end
    
    println("\nTest completed!")
end

# Export the main functions
export safe_reconstruct_geointeface, safe_reconstruct_archgdal, transform_and_reconstruct, affine_transform_geometry, test_geometry_reconstruction