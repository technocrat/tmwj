# Simple approach: Create new geometries in Cartesian coordinates
using GeoTables
using Meshes
using CoordRefSystems

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
function inset_state_basic(
    state::GeoTable{<:GeometrySet},
    rotation::Number,
    scale::Union{Number, Unitful.Quantity},
    x_offset::Union{Number, Unitful.Quantity},
    y_offset::Union{Number, Unitful.Quantity},
    direction::String = "ccw"
)
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
        
        # Get the exterior ring coordinates (first element)
        exterior_coords = coords[1]
        
        # Transform each coordinate
        new_coords = map(exterior_coords) do coord
            # Handle different coordinate formats
            if coord isa Vector && length(coord) >= 2
                lon, lat = coord[1], coord[2]
            else
                # Try to extract as tuple
                lon, lat = coord[1], coord[2]
            end
            
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
