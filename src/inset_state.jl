function inset_state(state::GeoTable{<:GeometrySet}, rotation::Number, scale::Number, x_offset::Number, y_offset::Number, direction::String = "ccw")
    θ = direction == "ccw" ? π/rotation : -π/rotation
    R = Angle2d(θ)
    S = Diagonal(SVector(scale, scale))
    A = S * R
    # increasing x moves the geometry to the right and increasing y lowers the geometry
    b = SVector(x_offset, y_offset)
    af = Affine(A, b)
    transformed_geometry = af.(state.geometry)
    return GeoTable(GeometrySet(transformed_geometry), vtable=state)
end