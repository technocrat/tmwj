using Pkg; Pkg.activate(@__DIR__)
using CairoMakie, ColorSchemes, CommonMark, CoordRefSystems,
      GeoDataFrames, GeoMakie, CSV, DataFrames, GeoIO,
      GeoStats, GeoTables, Humanize
import CoordRefSystems: Albers, EPSG, shift, Proj
import GeoMakie: GeoAxis, poly!, Legend, Label, text!, lines!
import Meshes: Proj

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
const VALID_STATEFPS = ["01", "02", "04", "05", "06", "08", "09", "10", "11", "12", "13", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "44", "45", "46", "47", "48", "49", "50", "51", "53", "54", "55", "56"]

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
    parser = Parser()
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

function get_inset_states(shape_file::String)
    conus_crs = CoordRefSystems.EPSG{5070}
    ak_crs = CoordRefSystems.EPSG{3338}
    projector_ak = Meshes.Proj(ak_crs)
    hi_crs = CoordRefSystems.shift(Albers{13, 8, 18, CoordRefSystems.NAD83}, lonₒ=-157)
    projector_hi = Meshes.Proj(hi_crs)
    data = DataFrame(GeoIO.load(shape_file))
    us_states = subset(data, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
    conus = GeoTable(us_states[us_states.STUSPS .!= "AK" .&& us_states.STUSPS .!= "HI", :]) |> Meshes.Proj(conus_crs)
    alaska = GeoTable(us_states[us_states.STUSPS .== "AK", :]) |> projector_ak  
    hawaii = GeoTable(us_states[us_states.STUSPS .== "HI", :]) |> projector_hi
    return conus, alaska, hawaii
end

# function plot_trauma_centers_geomakie()
    # Use data from full_plot.jl
    df = CSV.read("data/trauma_centers.csv", DataFrame)
    # source data has the geoid as an integer, but we will be joining on strings
    df.geoid = lpad.(df.geoid, 5, "0")
    select!(df, :geoid, :population, :is_trauma_center, :nearby)
    
    # County level data - load raw shapefile without projections
    tigerline_file = "data/2024_shp/cb_2024_us_county_500k.shp"
    data = GeoDataFrames.read(tigerline_file)
    
    # Filter to valid states
    data = subset(data, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
    
    # Split into regions
    conus_codes = setdiff(values(VALID_STATE_CODES), ["AK", "HI"])
    conus = subset(data, :STUSPS => ByRow(x -> x ∈ conus_codes))

    
    # select the only the columns we need for the main plot
    select!(conus, :geometry, :GEOID, :NAME, :STUSPS)

    
    #=
    source data has a column called nearby which is a boolean
    it is true if a Level 1 trauma center is within 50 miles of the county
    and counties with a Level 1 trauma center are always within 50 
    miles of themselves, so those counties are always true
    and that leads to duplicate rows, so we need to remove them
    the two boolean columns are used for coloring the counties
    =#
    for area in [conus]
        area.nearby[area.is_trauma_center] .= false
    end
    
    # join the county level data to the main plot
    conus = leftjoin(conus, df, on = :GEOID => :geoid)

    
    
    # Calculate statistics using conus data
    total_counties = size(conus, 1)
    trauma_counties = sum(skipmissing(conus.is_trauma_center))
    nearby_counties = sum(skipmissing(conus.nearby))
    other_counties = total_counties - trauma_counties - nearby_counties
    
    # Format statistics for display
    total_counties_fmt = lpad(with_commas(total_counties), 12)
    trauma_counties_fmt = lpad(with_commas(trauma_counties), 12)
    nearby_counties_fmt = lpad(with_commas(nearby_counties), 12)
    other_counties_fmt = lpad(with_commas(other_counties), 12)
    
    served = subset(conus, [:is_trauma_center, :nearby] => ByRow((tc, nb) -> (tc === true) || (nb === true)))
    percentage_counties_served = percent(nrow(served) / nrow(conus))
    percentage_served_population = percent(Float64(sum(skipmissing(served.population)) / sum(skipmissing(conus.population))))
    total_population = with_commas(sum(skipmissing(conus.population)))
    served_population = with_commas(sum(skipmissing(served.population)))
    all_counties = with_commas(nrow(conus))
    served_counties = with_commas(nrow(served))
    
    # Create table
    headers = ["Category", "Counties"]
    rows = [["Trauma Center", trauma_counties_fmt], ["Nearby", nearby_counties_fmt], ["Other", other_counties_fmt], ["Total", total_counties_fmt]]
    table_text = format_table_as_text(headers, rows)
    
    # Create descriptive text
    squib = "Of the $all_counties counties in the continental United States, $served_counties have a Level 1 trauma center within 50 miles, or $percentage_counties_served of the counties. This represents $served_population of the total population, or $percentage_served_population. Alaska has no Level 1 trauma centers and relies on air ambulance services to transport patients to Level 1 trauma centers in the lower 48 states. Hawaii has one Level 1 trauma center, in Honolulu, and relies on air ambulance services to transport patients from other islands."
    squib = hard_wrap(squib, 60)
    
    BuYlRd = reverse(colorschemes[:RdYlBu])
    trauma_center_color = BuYlRd[1]  # :is_trauma_center == true
    nearby_color = BuYlRd[2]         # :nearby == true  
    other_color = BuYlRd[7]          # :nearby == false    
    
    
    # Create figure
    f = Figure(size = (1000, 700))
    
    # Main map using GeoAxis with dest projection
    ga = GeoAxis(f[1, 1:3];
        dest = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
        aspect = DataAspect(),
        xgridvisible = false, ygridvisible = false,
        xticksvisible = false, yticksvisible = false,
        xticklabelsvisible = false, yticklabelsvisible = false,
    )


# here is where the fix is
    poly!(ga, conus.geometry, color=conus.colores, strokecolor=:white, strokewidth=0.5)
    #poly!(ga, GeoMakie.to_multipoly.(table.geometry))
    display(f)
    
    
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

function get_counties(shape_file::String)
    conus_crs = CoordRefSystems.EPSG{5070}
    ak_crs = CoordRefSystems.EPSG{3338}
    projector_ak = Proj(ak_crs)
    hi_crs = CoordRefSystems.shift(Albers{13, 8, 18, NAD83}, lonₒ=-157)
    projector_hi = Proj(hi_crs)
    data = DataFrame(GeoIO.load(shape_file))
    us_counties = subset(data, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
    conus = GeoTable(us_counties[us_counties.STUSPS .!= "AK" .&& us_counties.STUSPS .!= "HI", :]) |> Proj(conus_crs)
    alaska = GeoTable(us_counties[us_counties.STUSPS .== "AK", :]) |> projector_ak  
    hawaii = GeoTable(us_counties[us_counties.STUSPS .== "HI", :]) |> projector_hi
    return conus, alaska, hawaii
end
conus_discard, alaska, hawaii = get_counties(tigerline_file)
julia# Add categorical color column to DataFrames
for area_df in [alaska, hawaii]
    area_df.color_category = [area_df.is_trauma_center[i] === true ? "trauma" : 
                             area_df.nearby[i] === true ? "nearby" : "other" 
                             for i in eachindex(area_df.is_trauma_center)]
end

# Then in viz!:
viz!(ga, alaska_inset.geometry, color = alaska_inset.color_category,
     colormap = Dict("trauma" => trauma_center_color, "nearby" => nearby_color, "other" => other_color),
     strokecolor = :white, strokewidth = 0.5)
# dataframes

# tigerline data
tigerline_file = "data/2024_shp/cb_2024_us_county_500k.shp"

# trauma centers data
df = CSV.read("data/trauma_centers.csv", DataFrame)
# source data has the geoid and statefp as integers
# but we will be joining on strings which are 5 and 2 characters long
df.geoid = lpad.(df.geoid, 5, "0")
df.statefp = lpad.(df.statefp,2,"0")
df = subset(df, :statefp => ByRow(x -> x in VALID_STATEFPS))
df = unique(df, :geoid)
select!(df, :geoid, :population, :is_trauma_center, :nearby)

# descriptive statistics of trauma centers

total_counties = size(df, 1)
trauma_counties = sum(df.is_trauma_center)
nearby_counties = sum(df.nearby)
other_counties = total_counties - trauma_counties - nearby_counties
total_counties = lpad(with_commas(total_counties), 12)
trauma_counties = lpad(with_commas(trauma_counties), 12)
nearby_counties = lpad(with_commas(nearby_counties), 12)
other_counties = lpad(with_commas(other_counties), 12)
served = subset(df, [:is_trauma_center, :nearby] => ByRow((tc, nb) -> tc || nb))
percentage_counties_served = percent(nrow(served) / nrow(df))
percentage_served_population = percent(Float64(sum(served.population) / sum(df.population)))
total_population = with_commas(sum(df.population))
served_population = with_commas(sum(served.population))
all_counties = with_commas(nrow(df))
served_counties = with_commas(nrow(served))

headers = ["Category", "Counties"]
rows = [["Trauma Center", trauma_counties], ["Nearby", nearby_counties], ["Other", other_counties], ["Total", total_counties]]
table_text = format_table_as_text(headers, rows)

squib = "Of the $all_counties counties in the continental United States, $served_counties have a Level 1 trauma center within 50 miles, or $percentage_counties_served of the counties. This represents $served_population of the total population, or $percentage_served_population. Alaska has no Level 1 trauma centers and relies on air ambulance services to transport patients to Level 1 trauma centers in the lower 48 states. Hawaii has one Level 1 trauma center, in Honolulu, and relies on air ambulance services to transport patients from other islands."
squib = hard_wrap(squib, 60)

# geometries



# Legend to the right
legend = Legend(f[2, 3],
    [PolyElement(color=trauma_center_color, strokecolor=:black),
     PolyElement(color=nearby_color, strokecolor=:black),
     PolyElement(color=other_color, strokecolor=:black)],
    ["Trauma Centers", "Within 50 Miles", "Other Counties"],
    "County Categories", halign=:right, fontsize=10
)

# Title spanning full width
Label(f[0, :], "US Counties: Level 1 Trauma Centers and Nearby Areas"  , fontsize = 20)

# Caption below
Label(f[3, 3], "Source: Richard Careaga from https://en.wikipedia.org/wiki/List_of_trauma_centers_in_the_United_States", fontsize = 10, halign=:right)

# Summary table
Label(f[2, 2], table_text; font="DejaVu Sans Mono", fontsize=10, halign=:left, valign=:top)

# Summary text
Label(f[2, 1], squib; fontsize=10, halign=:left, valign=:top, justification=:left)

# North arrow with rotation capability
north_arrow = "\u21E7\nN"
text!(f.scene, north_arrow, 
      position=(0.85, 0.6),
      # rotation=π/6,          # 30 degrees (uncomment to rotate)
      space=:relative,
      align=(:left, :top), 
      fontsize=36, color=:black)

# Scale bar positioned under the north arrow (in relative coordinates)
# Calculate scale bar length based on actual map scale
map_width = 4.4e6  # approximate width of CONUS in meters
scale_bar_length = (80467.2 / map_width) * 0.8  # 50 miles as fraction of map width
scale_bar_x = 0.85
scale_bar_y = 0.45
lines!(f.scene, [scale_bar_x - scale_bar_length/2, scale_bar_x + scale_bar_length/2], 
       [scale_bar_y, scale_bar_y], 
       space=:relative, color=:black, linewidth=3)

# Scale bar label positioned under the scale bar
text!(f.scene, "50 mi", 
      position=(scale_bar_x, scale_bar_y - 0.02),  # positioned under the scale bar
      space=:relative,
      align=(:center, :top), 
      fontsize=14, color=:black)









display(f)
