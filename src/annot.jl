# using Pkg
# Pkg.activate(@__DIR__)
using CairoMakie, ColorSchemes, CommonMark, CoordRefSystems,
       CSV, DataFrames, GeoIO, GeoDataFrames, GeoMakie,
       GeoStats, GeoTables, Humanize, Meshes, StaticArrays, Tables
import GeoStats: viz!
using Unitful

# constants
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

# functions

function with_commas(x)
    x = Int64.(x)
    return Humanize.digitsep.(x)
end

function percent(x::Float64)
    x = Float64(x)
    return string(round(x * 100; digits=2)) * "%"
end 

function hard_wrap(text::String, width::Int)
    """
    Hard-wrap text at the specified width, breaking at word boundaries when possible.
    Each line is right-padded to the specified width.
    
    Args:
        text: The text to wrap
        width: Maximum line width in characters
    
    Returns:
        String with line breaks inserted and each line padded to width
    """
    if width <= 0
        return text
    end
    
    words = split(text, " ")
    lines = String[]
    current_line = ""
    
    for word in words
        # If adding this word would exceed the width
        if length(current_line) + length(word) + 1 > width
            # If current line is not empty, start a new line
            if !isempty(current_line)
                push!(lines, rpad(current_line, width))
                current_line = word
            else
                # Current line is empty, so the word itself is too long
                # Break the word if it exceeds width
                if length(word) > width
                    # Break the word at the width limit
                    push!(lines, rpad(word[1:width], width))
                    current_line = word[width+1:end]
                else
                    current_line = word
                end
            end
        else
            # Add word to current line
            if isempty(current_line)
                current_line = word
            else
                current_line *= " " * word
            end
        end
    end
    
    # Add the last line if it's not empty
    if !isempty(current_line)
        push!(lines, rpad(current_line, width))
    end
    
    return join(lines, "\n")
end

function format_table_as_text(headers::Vector{String}, rows::Vector{Vector{String}}, 
    padding::Int=2)
    all_rows = [headers; rows]

    # Calculate column widths
    col_widths = Int[]
    for col in 1:length(headers)
    max_width = maximum(length(row[col]) for row in all_rows)
    push!(col_widths, max_width + padding)
    end

    # Format rows
    formatted_lines = String[]

    # Header
    header_line = join([rpad(headers[i], col_widths[i]) for i in 1:length(headers)], "│")
    push!(formatted_lines, "│" * header_line * "│")

    # Separator
    separator = "├" * join([repeat("─", col_widths[i]) for i in 1:length(headers)], "┼") * "┤"
    push!(formatted_lines, separator)

    # Data rows
    for row in rows
    data_line = join([rpad(row[i], col_widths[i]) for i in 1:length(row)], "│")
    push!(formatted_lines, "│" * data_line * "│")
    end

    # Top and bottom borders
    top_border = "┌" * join([repeat("─", col_widths[i]) for i in 1:length(headers)], "┬") * "┐"
    bottom_border = "└" * join([repeat("─", col_widths[i]) for i in 1:length(headers)], "┴") * "┘"

    return join([top_border, formatted_lines..., bottom_border], "\n")
end

# Your working inset function
function inset_state(
    state::GeoTable{<:GeometrySet},
    rotation::Number,
    scale::Union{Number, Unitful.Quantity},
    x_offset::Union{Number, Unitful.Quantity},
    y_offset::Union{Number, Unitful.Quantity},
    direction::String = "ccw"
)
    θ = direction == "ccw" ? π/rotation : -π/rotation
    S = Diagonal(SVector(scale, scale))
    R = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    A = S * R
    b = SVector(x_offset, y_offset)
    af = Affine(A, b)

    # Helper to transform a single geometry object
    function transform_geom(coords)
        # Recursively handle nested structures (MultiPolygons, etc.)
        if eltype(coords) <: AbstractVector
            return [transform_geom(sub) for sub in coords]
        else
            # Flat ring: transform each point, handling variable coordinate counts
            return [begin
                c = Tuple(p)
                if length(c) >= 2
                    # Create SVector with compatible types
                    T = promote_type(typeof(c[1]), typeof(x_offset))
                    x = T(c[1])
                    y = T(c[2])
                    af(SVector(x, y))
                elseif length(c) == 1
                    T = promote_type(typeof(c[1]), typeof(x_offset))
                    x = T(c[1])
                    y = zero(T)
                    af(SVector(x, y))
                else
                    p  # Return original if no coordinates
                end
            end for p in coords]
        end
    end

    # Rebuild geometry objects of the same type as original
    transformed_geometry = map(state.geometry) do geom
        coords = GeoInterface.coordinates(geom)
        new_coords = transform_geom(coords)
        typeof(geom)(new_coords)
    end
    return GeoTable(GeometrySet(transformed_geometry), vtable=state)
end

# Your working get_states function (adapted for counties)
function get_counties(shape_file::String)
    conus_crs = CoordRefSystems.EPSG{5070}
    ak_crs = CoordRefSystems.EPSG{3338}
    projector_ak = Meshes.Proj(ak_crs)
    hi_crs = CoordRefSystems.shift(Albers{13, 8, 18, NAD83}, lonₒ=-157)
    projector_hi = Meshes.Proj(hi_crs)
    data = DataFrame(GeoIO.load(shape_file))
    us_counties = subset(data, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
    conus = GeoTable(us_counties[us_counties.STUSPS .!= "AK" .&& us_counties.STUSPS .!= "HI", :]) |> Meshes.Proj(conus_crs)
    alaska = GeoTable(us_counties[us_counties.STUSPS .== "AK", :]) |> projector_ak  
    hawaii = GeoTable(us_counties[us_counties.STUSPS .== "HI", :]) |> projector_hi
    return conus, alaska, hawaii
end

function plot_trauma_centers_geomakie()
    # Load trauma center data
    df = CSV.read("data/trauma_centers.csv", DataFrame)
    df.geoid = lpad.(df.geoid, 5, "0")
    select!(df, :geoid, :population, :is_trauma_center, :nearby)
    
    # Clean up nearby data
    df.nearby[df.is_trauma_center] .= false
    
    # County level data using your working pattern
    tigerline_file = "data/2024_shp/cb_2024_us_county_500k.shp"
    conus_geo, alaska_geo, hawaii_geo = get_counties(tigerline_file)
    
    # Convert to DataFrames for joining
    conus_df = DataFrame(conus_geo)
    alaska_df = DataFrame(alaska_geo)
    hawaii_df = DataFrame(hawaii_geo)
    
    # Join trauma data
    conus_df = leftjoin(conus_df, df, on = :GEOID => :geoid)
    alaska_df = leftjoin(alaska_df, df, on = :GEOID => :geoid)
    hawaii_df = leftjoin(hawaii_df, df, on = :GEOID => :geoid)
    
    # Calculate statistics using conus data
    total_counties = size(conus_df, 1)
    trauma_counties = sum(skipmissing(conus_df.is_trauma_center))
    nearby_counties = sum(skipmissing(conus_df.nearby))
    other_counties = total_counties - trauma_counties - nearby_counties
    
    # Format statistics for display
    total_counties_fmt = lpad(with_commas(total_counties), 12)
    trauma_counties_fmt = lpad(with_commas(trauma_counties), 12)
    nearby_counties_fmt = lpad(with_commas(nearby_counties), 12)
    other_counties_fmt = lpad(with_commas(other_counties), 12)
    
    served = subset(conus_df, [:is_trauma_center, :nearby] => ByRow((tc, nb) -> (tc === true) || (nb === true)))
    percentage_counties_served = percent(nrow(served) / nrow(conus_df))
    percentage_served_population = percent(Float64(sum(skipmissing(served.population)) / sum(skipmissing(conus_df.population))))
    total_population = with_commas(sum(skipmissing(conus_df.population)))
    served_population = with_commas(sum(skipmissing(served.population)))
    all_counties = with_commas(nrow(conus_df))
    served_counties = with_commas(nrow(served))
    
    # Create table
    headers = ["Category", "Counties"]
    rows = [["Trauma Center", trauma_counties_fmt], ["Nearby", nearby_counties_fmt], ["Other", other_counties_fmt], ["Total", total_counties_fmt]]
    table_text = format_table_as_text(headers, rows)
    
    # Create descriptive text
    squib = "Of the $all_counties counties in the continental United States, $served_counties have a Level 1 trauma center within 50 miles, or $percentage_counties_served of the counties. This represents $served_population of the total population, or $percentage_served_population. Alaska has no Level 1 trauma centers and relies on air ambulance services to transport patients to Level 1 trauma centers in the lower 48 states. Hawaii has one Level 1 trauma center, in Honolulu, and relies on air ambulance services to transport patients from other islands."
    squib = hard_wrap(squib, 60)
    
    # Define colors     
    BuYlRd = reverse(colorschemes[:RdYlBu])
    trauma_center_color = BuYlRd[1]  # :is_trauma_center == true
    nearby_color = BuYlRd[2]         # :nearby == true  
    other_color = BuYlRd[7]          # :nearby == false
    
    # Plot using viz! with direct color specification instead of accessing geotable attributes
    # Create color vectors directly from the DataFrames
    conus_colors = [conus_df.is_trauma_center[i] === true ? trauma_center_color : 
                   conus_df.nearby[i] === true ? nearby_color : other_color 
                   for i in eachindex(conus_df.is_trauma_center)]
    
    alaska_colors = [alaska_df.is_trauma_center[i] === true ? trauma_center_color : 
                    alaska_df.nearby[i] === true ? nearby_color : other_color 
                    for i in eachindex(alaska_df.is_trauma_center)]
    
    hawaii_colors = [hawaii_df.is_trauma_center[i] === true ? trauma_center_color : 
                    hawaii_df.nearby[i] === true ? nearby_color : other_color 
                    for i in eachindex(hawaii_df.is_trauma_center)]
    
    # Create insets using manual coordinate transformation (simpler approach)
    # We'll transform the coordinates manually and create simple polygons
    alaska_inset_geoms = []
    for geom in alaska_geo.geometry
        coords = GeoInterface.coordinates(geom)
        if !isempty(coords)
            transformed = transform_geom_coords(coords, 0.25, π/18, [-2_000_000.0, 420_000.0])
            if !isempty(transformed)
                if eltype(transformed) <: AbstractVector{<:Real}
                    rings = to_points.(transformed)
                    push!(alaska_inset_geoms, GeometryBasics.Polygon(rings[1], rings[2:end]))
                elseif eltype(transformed) <: AbstractVector
                    for poly in transformed
                        rings = to_points.(poly)
                        push!(alaska_inset_geoms, GeometryBasics.Polygon(rings[1], rings[2:end]))
                    end
                end
            end
        end
    end
    
    hawaii_inset_geoms = []
    for geom in hawaii_geo.geometry
        coords = GeoInterface.coordinates(geom)
        if !isempty(coords)
            transformed = transform_geom_coords(coords, 0.5, π/24, [-1_250_000.0, 250_000.0])
            if !isempty(transformed)
                if eltype(transformed) <: AbstractVector{<:Real}
                    rings = to_points.(transformed)
                    push!(hawaii_inset_geoms, GeometryBasics.Polygon(rings[1], rings[2:end]))
                elseif eltype(transformed) <: AbstractVector
                    for poly in transformed
                        rings = to_points.(poly)
                        push!(hawaii_inset_geoms, GeometryBasics.Polygon(rings[1], rings[2:end]))
                    end
                end
            end
        end
    end
    

    

    # Create figure with proper aspect control
    f = Figure(size = (1400, 900))
    
    # Create an Axis instead of GeoAxis for better control
    ax = Axis(f[1, 1:3], aspect = DataAspect(),
              xgridvisible = false, ygridvisible = false,
              xticksvisible = false, yticksvisible = false,
              xticks = nothing, yticks = nothing,
              xticklabelsvisible = false, yticklabelsvisible = false,
              leftspinevisible = false, rightspinevisible = false,
              topspinevisible = false, bottomspinevisible = false)
    
    # Plot using viz! with colors passed directly
    viz!(ax, conus_geo.geometry, color = conus_colors, strokecolor = :white, strokewidth = 0.5)
    
    # Plot Alaska inset with colors
    for (i, geom) in enumerate(alaska_inset_geoms)
        if i <= length(alaska_colors)
            viz!(ax, geom, color = alaska_colors[i], strokecolor = :white, strokewidth = 0.5)
        end
    end
    
    # Plot Hawaii inset with colors
    for (i, geom) in enumerate(hawaii_inset_geoms)
        if i <= length(hawaii_colors)
            viz!(ax, geom, color = hawaii_colors[i], strokecolor = :white, strokewidth = 0.5)
        end
    end
    
    
    # Legend to the right
    legend = Legend(f[2, 3],
        [PolyElement(color=trauma_center_color, strokecolor=:black),
         PolyElement(color=nearby_color, strokecolor=:black),
         PolyElement(color=other_color, strokecolor=:black)],
        ["Trauma Centers", "Within 50 Miles", "Other Counties"],
        "County Categories", halign=:right, fontsize=10
    )
    
    # Title spanning full width
    Label(f[0, :], "US Counties: Level 1 Trauma Centers and Nearby Areas", fontsize = 20)
    
    # Caption below
    Label(f[3, 3], "Source: Richard Careaga from https://en.wikipedia.org/wiki/List_of_trauma_centers_in_the_United_States", fontsize = 10, halign=:right)
    
    # Summary table
    Label(f[2, 2], table_text; font="DejaVu Sans Mono", fontsize=10, halign=:left, valign=:top)
    
    # Summary text
    Label(f[2, 1], squib; fontsize=10, halign=:left, valign=:top, justification=:left)
    
    # North arrow
    north_arrow = "\u21E7\nN"
    text!(f.scene, north_arrow, 
          position=(0.85, 0.6),
          space=:relative,
          align=(:left, :top), 
          fontsize=36, color=:black)
    
    # Scale bar
    map_width = 4.4e6  # approximate width of CONUS in meters
    scale_bar_length = (80467.2 / map_width) * 0.8  # 50 miles as fraction of map width
    scale_bar_x = 0.85
    scale_bar_y = 0.45
    lines!(f.scene, [scale_bar_x - scale_bar_length/2, scale_bar_x + scale_bar_length/2], 
           [scale_bar_y, scale_bar_y], 
           space=:relative, color=:black, linewidth=3)
    
    # Scale bar label
    text!(f.scene, "50 mi", 
          position=(scale_bar_x, scale_bar_y - 0.02),
          space=:relative,
          align=(:center, :top), 
          fontsize=14, color=:black)
    
    return f
end

# Example usage of the function
f = plot_trauma_centers_geomakie()
display(f)