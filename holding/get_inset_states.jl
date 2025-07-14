function get_inset_states(shape_file::String)
    conus_crs = EPSG{5070}
    ak_crs = EPSG{3338}
    projector_ak = Proj(ak_crs)
    hi_crs = CoordRefSystems.shift(Albers{13, 8, 18, NAD83}, lonₒ=-157)
    projector_hi = Proj(hi_crs)
    data = DataFrame(GeoIO.load(shape_file))
    us_states = subset(data, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
    conus = GeoTable(us_states[us_states.STUSPS .!= "AK" .&& us_states.STUSPS .!= "HI", :]) |> Proj(conus_crs)
    alaska = GeoTable(us_states[us_states.STUSPS .== "AK", :]) |> projector_ak  
    hawaii = GeoTable(us_states[us_states.STUSPS .== "HI", :]) |> projector_hi
    return conus, alaska, hawaii
end
