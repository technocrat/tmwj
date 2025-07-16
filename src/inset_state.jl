function inset_state(
    state::GeoTable{<:GeometrySet},
    rotation::Number,
    scale::Union{Number, Unitful.Quantity},
    x_offset::Union{Number, Unitful.Quantity},
    y_offset::Union{Number, Unitful.Quantity},
    direction::String = "ccw"
)
    # Extract coordinates and convert to simple x,y values
    θ = direction == "ccw" ? π/rotation : -π/rotation
    cos_θ, sin_θ = cos(θ), sin(θ)
    
    # Convert to suitable projected coordinates (UTM for Hawaii)
    target_crs = EPSG{32604}
    
    transformed_geometries = map(state.geometry) do geom
        if geom isa PolyArea
            # Get the exterior boundary
            exterior = boundary(geom)
            
            # Extract points and convert
            points = vertices(exterior)
            new_points = map(points) do pt
                coord = coordinates(pt)
                
                # Convert to UTM
                utm_coord = convert(target_crs, coord)
                x = ustrip(utm_coord.x)
                y = ustrip(utm_coord.y)
                
                # Apply transformations
                x_scaled = x * ustrip(scale)
                y_scaled = y * ustrip(scale)
                x_rot = x_scaled * cos_θ - y_scaled * sin_θ
                y_rot = x_scaled * sin_θ + y_scaled * cos_θ
                x_final = x_rot + ustrip(x_offset)
                y_final = y_rot + ustrip(y_offset)
                
                # Create new point in target CRS
                Point(target_crs(x_final, y_final))
            end
            
            # Create new polygon
            new_ring = Ring(new_points)
            PolyArea([new_ring])
        else
            geom  # Handle other types as needed
        end
    end
    
    return GeoTable(GeometrySet(transformed_geometries), vtable=values(state))
end