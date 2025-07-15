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

const VALID_STATEFPS = ["01", "02", "04", "05", "06", "08", "09", "10", "11", "12", "13", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "44", "45", "46", "47", "48", "49", "50", "51", "53", "54", "55", "56"]



function plot_states_with_inset(conus = conus, alaska_inset = alaska_inset, hawaii_inset = hawaii_inset)
    viz(conus.geometry)
    viz!(alaska_inset.geometry)
    viz!(hawaii_inset.geometry)
    display(current_figure())
end

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

function get_states(shape_file::String)
    conus_crs = CoordRefSystems.EPSG{5070}
    # ak_crs = CoordRefSystems.shift(Albers{50,55,65,NAD83}, lonₒ=-154)
    ak_crs = CoordRefSystems.EPSG{3338}
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
alaska_inset = inset_state(alaska, 18, 0.25, -2_000_000, 420_000, "ccw")
hawaii_inset = inset_state(hawaii, 24, 0.5, -1_250_000, 250_000, "ccw")
plot_states_with_inset(conus, alaska_inset, hawaii_inset)

