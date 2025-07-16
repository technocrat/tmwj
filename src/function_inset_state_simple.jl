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
    
    # Convert scale and offsets to plain numbers
    scale_val = isa(scale, Number) ? scale : ustrip(scale)
    x_offset_val = isa(x_offset, Number) ? x_offset : ustrip(x_offset)
    y_offset_val = isa(y_offset, Number) ? y_offset : ustrip(y_offset)
    
    transformed_geometries = map(state.geometry) do geom
        # Get raw coordinates using GeoInterface
        coords = GeoInterface.coordinates(geom)
        new_coords = transform_coordinate_structure(coords) do point
            if length(point) >= 2
                # Work directly with lat/lon as x,y for geometric transformation
                # Note: This treats lat/lon as Cartesian - appropriate for small regions
                lon, lat = point[1], point[2]
                
                # Apply transformations
                x_scaled = lon * scale_val
                y_scaled = lat * scale_val
                x_rot = x_scaled * cos_θ - y_scaled * sin_θ
                y_rot = x_scaled * sin_θ + y_scaled * cos_θ
                x_final = x_rot + x_offset_val
                y_final = y_rot + y_offset_val
                
                [x_final, y_final]
            else
                point
            end
        end
        
        # Reconstruct geometry with same type
        typeof(geom)(new_coords)
    end
    
    return GeoTable(GeometrySet(transformed_geometries), vtable=values(state))
end

function transform_coordinate_structure(transform_func, coords)
    if coords isa AbstractVector && length(coords) > 0 && coords[1] isa AbstractVector
        # Nested structure (polygon rings, etc.)
        return [transform_coordinate_structure(transform_func, sub_coords) for sub_coords in coords]
    else
        # Flat coordinate array
        return [transform_func(point) for point in coords]
    end
end

# Debug function to inspect coordinate system
function inspect_coordinates(state::GeoTable)
    println("Number of geometries: ", length(state.geometry))
    if length(state.geometry) > 0
        first_geom = state.geometry[1]
        println("First geometry type: ", typeof(first_geom))
        
        if first_geom isa PolyArea
            boundary_ring = boundary(first_geom)
            first_point = first(vertices(boundary_ring))
            coord = coordinates(first_point)
            println("First coordinate: ", coord)
            println("Coordinate type: ", typeof(coord))
            println("CRS: ", crs(coord))
        end
    end
end

hawaii_inset = inset_state_simple(hawaii_with_color, 24, 0.5, -1_250_000.0, 250_000, "ccw")

# Check if it worked
hawaii_coords = GeoInterface.coordinates(hawaii_inset.geometry[1])
println("First few coordinates: ", hawaii_coords[1][1][1:3])