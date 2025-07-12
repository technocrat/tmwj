using Pkg; Pkg.activate(@__DIR__)
using CoordRefSystems
using CairoMakie
using DataFrames
using GeoIO
using GeoStats
using GeoTables
using Meshes  # Provides Affine, Angle2d, etc.
using StaticArrays  # For SVector
using Unitful

const VALID_STATE_CODES = Dict(
    "Alabama" => "AL", "Alaska" => "AK", "Arizona" => "AZ", "Arkansas" => "AR",
    "California" => "CA", "Colorado" => "CO", "Connecticut" => "CT", "Delaware" => "DE",
    "Florida" => "FL", "Georgia" => "GA", "Hawaii" => "HI", "Idaho" => "ID",
    "Illinois" => "IL", "Indiana" => "IN", "Iowa" => "IA", "Kansas" => "KS",
    "Kentucky" => "KY", "Louisiana" => "LA", "Maine" => "ME", "Maryland" => "MD",
    "Massachusetts" => "MA", "Michigan" => "MI", "Minnesota" => "MN", "Mississippi" => "MS",
    "Missouri" => "MO", "Montana" => "MT", "Nebraska" => "NE", "Nevada" => "NV",
    "New Hampshire" => "NH", "New Jersey" => "NJ", "New Mexico" => "NM", "New York" => "NY",
    "North Carolina" => "NC", "North Dakota" => "ND", "Ohio" => "OH", "Oklahoma" => "OK",
    "Oregon" => "OR", "Pennsylvania" => "PA", "Rhode Island" => "RI", "South Carolina" => "SC",
    "South Dakota" => "SD", "Tennessee" => "TN", "Texas" => "TX", "Utah" => "UT",
    "Vermont" => "VT", "Virginia" => "VA", "Washington" => "WA", "West Virginia" => "WV",
    "Wisconsin" => "WI", "Wyoming" => "WY", "District of Columbia" => "DC"
)
tigerline_file = "data/2024_shp/cb_2024_us_state_500k.shp"
function get_states(shape_file::String)
    conus_crs = EPSG{5070}
    ak_crs = CoordRefSystems.shift(Albers{50,55,65,NAD83}, lonₒ=-154)
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

conus, alaska, hawaii = get_states(tigerline_file)

function inset_state(state::GeoTable{<:GeometrySet}, rotation::Number, scale::Number, x_offset::Number, y_offset::Number)
    θ = -π/rotation 
    R = Angle2d(θ)
    S = Diagonal(SVector(scale, scale))
    A = S * R
    # AK decreasing x moves the geometry to the left and increasing y lowers the geometry
    # HI decreasing x moves the geometry to the right and increasing y raises the geometry
    af = Affine(A, SVector(x_offset, y_offset))
    return GeoTable(GeometrySet(af.(state.geometry)), vtable=state)
end

alaska_transformed = inset_state(alaska, 18, 0.25, -2_000_000, 420_000)
hawaii_transformed = inset_state(hawaii, 24, 0.5, -1_250_000, 250_000)




viz(conus.geometry)
viz!(alaska_transformed.geometry)
viz!(hawaii_transformed.geometry)


display(current_figure())