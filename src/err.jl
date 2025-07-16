# Simple approach: Create new geometries in Cartesian coordinates
using GeoTables
using Meshes: Point, Ring, PolyArea
using CoordRefSystems: GeodeticLatLon, NAD83
using Unitful

function inset_state_simple(
    state::GeoTable{<:GeometrySet},
    rotation::Number,
    scale::Union{Number, Unitful.Quantity},
    x_offset::Union{Number, Unitful.Quantity},
    y_offset::Union{Number, Unitful.Quantity},
    direction::String = "ccw"
)
    θ = direction == "ccw" ? π/rotation : -π/rotation
    cos_θ, sin_θ = cos(θ), sin(θ)
    
    # Convert to plain numbers
    scale_val = isa(scale, Number) ? scale : ustrip(scale)
    x_offset_val = isa(x_offset, Number) ? x_offset : ustrip(x_offset)
    y_offset_val = isa(y_offset, Number) ? y_offset : ustrip(y_offset)
    
    transformed_geometries = map(state.geometry) do geom
        # Extract coordinates using GeoInterface
        coords = GeoInterface.coordinates(geom)
        
        # Transform the coordinate arrays
        new_coords = transform_coords_recursive(coords, scale_val, cos_θ, sin_θ, x_offset_val, y_offset_val)
        
        # Create new geometry in simple Cartesian coordinates
        if geom isa PolyArea
            # Create points from transformed coordinates
            exterior_coords = new_coords[1]  # First ring is exterior
            points = [Point(Cartesian(coord[1], coord[2])) for coord in exterior_coords]
            
            # Create rings
            exterior_ring = Ring(points)
            
            # Handle holes if they exist
            if length(new_coords) > 1
                hole_rings = [Ring([Point(Cartesian(coord[1], coord[2])) for coord in hole_coords]) 
                             for hole_coords in new_coords[2:end]]
                PolyArea([exterior_ring, hole_rings...])
            else
                PolyArea([exterior_ring])
            end
        else
            # For other geometry types, create appropriate Cartesian geometry
            # This is a simplified approach - you may need to handle other types
            geom
        end
    end
    
    return GeoTable(GeometrySet(transformed_geometries), vtable=values(state))
end

function transform_coords_recursive(coords, scale_val, cos_θ, sin_θ, x_offset_val, y_offset_val)
    if coords isa Vector && length(coords) > 0
        if coords[1] isa Vector
            if coords[1][1] isa Vector
                # Three levels deep - polygon with potential holes
                return [transform_coords_recursive(ring, scale_val, cos_θ, sin_θ, x_offset_val, y_offset_val) 
                       for ring in coords]
            else
                # Two levels deep - single ring
                return [transform_single_coord(coord, scale_val, cos_θ, sin_θ, x_offset_val, y_offset_val) 
                       for coord in coords]
            end
        else
            # Single coordinate
            return transform_single_coord(coords, scale_val, cos_θ, sin_θ, x_offset_val, y_offset_val)
        end
    else
        return coords
    end
end

function transform_single_coord(coord, scale_val, cos_θ, sin_θ, x_offset_val, y_offset_val)
    if length(coord) >= 2
        # Treat lon, lat as x, y
        lon, lat = coord[1], coord[2]
        
        # Apply transformations
        x_scaled = lon * scale_val
        y_scaled = lat * scale_val
        x_rot = x_scaled * cos_θ - y_scaled * sin_θ
        y_rot = x_scaled * sin_θ + y_scaled * cos_θ
        x_final = x_rot + x_offset_val
        y_final = y_rot + y_offset_val
        
        [x_final, y_final]
    else
        coord
    end
end

# Debug function to understand coordinate structure
function debug_coordinates(state::GeoTable)
    if length(state.geometry) > 0
        geom = state.geometry[1]
        coords = GeoInterface.coordinates(geom)
        println("Coordinate structure:")
        println("  Type: ", typeof(coords))
        println("  Length: ", length(coords))
        if length(coords) > 0
            println("  First element type: ", typeof(coords[1]))
            if coords[1] isa Vector && length(coords[1]) > 0
                println("  First coord type: ", typeof(coords[1][1]))
                println("  First coord value: ", coords[1][1])
                if coords[1][1] isa Vector && length(coords[1][1]) > 0
                    println("  First point: ", coords[1][1][1])
                end
            end
        end
    end
end
# Simple function for lat/lon coordinates (degrees)
function inset_state_latlon(
    state::GeoTable{<:GeometrySet},
    rotation::Number,
    scale::Union{Number, Unitful.Quantity},
    x_offset::Union{Number, Unitful.Quantity},
    y_offset::Union{Number, Unitful.Quantity},
    direction::String = "ccw"
)

    
    θ = direction == "ccw" ? π/rotation : -π/rotation
    cos_θ, sin_θ = cos(θ), sin(θ)
    
    scale_val = isa(scale, Number) ? scale : ustrip(scale)
    x_offset_val = isa(x_offset, Number) ? x_offset : ustrip(x_offset)
    y_offset_val = isa(y_offset, Number) ? y_offset : ustrip(y_offset)
    
    transformed_data = map(1:length(state.geometry)) do i
        geom = state.geometry[i]
        coords = GeoInterface.coordinates(geom)
        exterior_coords = coords[1][1]  # First polygon, first ring
        
        # Transform each coordinate (treating as degrees)
        new_coords = map(exterior_coords) do coord
            lon, lat = coord[1], coord[2]
            
            # Center Hawaii coordinates around 0 for rotation
            lon_centered = lon - (-156.0)  # Center around Hawaii's approximate longitude
            lat_centered = lat - 19.5      # Center around Hawaii's approximate latitude
            
            # Apply scale and rotation
            x_scaled = lon_centered * scale_val
            y_scaled = lat_centered * scale_val
            x_rot = x_scaled * cos_θ - y_scaled * sin_θ
            y_rot = x_scaled * sin_θ + y_scaled * cos_θ
            
            # Apply offset to final position and add z-coordinate if needed
            x_final = x_rot + x_offset_val
            y_final = y_rot + y_offset_val
            
            # Check if we need 3D coordinates by examining original data
            if length(exterior_coords[1]) >= 3
                z_coord = exterior_coords[1][3]  # Use original z
                (x_final, y_final, z_coord)
            else
                (x_final, y_final, 0.0)  # Add z=0 for 3D compatibility
            end
        end
        
        # Create polygon with same CRS as original
        if length(state.geometry) > 0
            first_geom = state.geometry[1]
            if first_geom isa PolyArea
                # Get the coordinate type from the original geometry
                boundary_ring = boundary(first_geom)
                first_vertex = first(vertices(boundary_ring))
                coord_type = typeof(coordinates(first_vertex))
                
                # Create new points with the same coordinate type
                points = if length(new_coords[1]) >= 3
                    [Point(coord_type(coord[1], coord[2], coord[3])) for coord in new_coords]
                else
                    [Point(coord_type(coord[1], coord[2])) for coord in new_coords]
                end
                ring = Ring(points)
                PolyArea([ring])
            else
                # Fallback to simple lat/lon
                points = [Point(GeodeticLatLon{NAD83}(coord[2], coord[1])) for coord in new_coords]
                ring = Ring(points)
                PolyArea([ring])
            end
        else
            # Fallback
            points = [Point(GeodeticLatLon{NAD83}(coord[2], coord[1])) for coord in new_coords]
            ring = Ring(points)
            PolyArea([ring])
        end
    end
    
    return GeoTable(GeometrySet(transformed_data), vtable=values(state))
end

function inset_state_simple_cartesian(
    state::GeoTable{<:GeometrySet},
    rotation::Number,
    scale::Union{Number, Unitful.Quantity},
    x_offset::Union{Number, Unitful.Quantity},
    y_offset::Union{Number, Unitful.Quantity},
    direction::String = "ccw"
)
    using Meshes: Point, Ring, PolyArea, Cartesian
    
    # Use the raw coordinate transformation approach but create completely new simple geometries
    θ = direction == "ccw" ? π/rotation : -π/rotation
    cos_θ, sin_θ = cos(θ), sin(θ)
    
    scale_val = isa(scale, Number) ? scale : ustrip(scale)
    x_offset_val = isa(x_offset, Number) ? x_offset : ustrip(x_offset)
    y_offset_val = isa(y_offset, Number) ? y_offset : ustrip(y_offset)
    
    # Extract all coordinate data and transform it
    transformed_data = map(1:length(state.geometry)) do i
        geom = state.geometry[i]
        coords = GeoInterface.coordinates(geom)
        
        # Handle the 4-level nesting: coords[1][1] gives us the actual coordinate array
        exterior_coords = coords[1][1]  # First polygon, first ring
        
        # Transform each coordinate
        new_coords = map(exterior_coords) do coord
            # coord is now a Vector{Float64} like [-156.054367, 19.738807]
            lon, lat = coord[1], coord[2]
            
            # Apply transformations
            x_scaled = lon * scale_val
            y_scaled = lat * scale_val
            x_rot = x_scaled * cos_θ - y_scaled * sin_θ
            y_rot = x_scaled * sin_θ + y_scaled * cos_θ
            x_final = x_rot + x_offset_val
            y_final = y_rot + y_offset_val
            
            (x_final, y_final)
        end
        
        # Create simple polygon in Cartesian coordinates
        points = [Point(Cartesian(coord[1], coord[2])) for coord in new_coords]
        ring = Ring(points)
        PolyArea([ring])
    end
    
    return GeoTable(GeometrySet(transformed_data), vtable=values(state))
end