using Pkg; Pkg.activate(@__DIR__)
include("src/inset_packages.jl")
include("src/inset_functions.jl")

alaska_inset = inset_state(alaska, 18, 0.25, -2_000_000, 420_000)
hawaii_inset = inset_state(hawaii, 24, 0.5, -1_250_000, 250_000)

function get_states(shape_file::String)
    conus_crs = EPSG{5070}
    # ak_crs = CoordRefSystems.shift(Albers{50,55,65,NAD83}, lonₒ=-154)
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

tigerline_file = "data/2024_shp/cb_2024_us_state_500k.shp"
conus, alaska, hawaii = get_states(tigerline_file)




