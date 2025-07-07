using CairoMakie
using ColorSchemes
using GeoMakie

"""
    plot_base_map(df)

Creates a choropleth map of US counties showing Level 1 trauma centers and nearby areas.

# Arguments
- `df`: DataFrame containing county geometries and trauma center data with columns:
    - `geom`: County geometry objects
    - `is_trauma_center`: Boolean indicating if county has a Level 1 trauma center
    - `nearby`: Boolean indicating if county is within 50 miles of a trauma center

# Returns
- `Tuple` containing:
    - `Figure` object containing the plotted map
    - `trauma_center_color`: Color for counties with Level 1 trauma centers
    - `nearby_color`: Color for counties within 50 miles of trauma centers
    - `other_color`: Color for all other counties

The map uses the ColorBrewer PuBu_3 color scheme where:
- Dark blue: Counties with Level 1 trauma centers
- Medium blue: Counties with a center within 50 miles of the center of a county with one or more Level 1 trauma centers  
- Light purplish blue: All other counties 
"""
function plot_base_map(df)
    fig = Figure(size = (1400, 800))
    ga = GeoAxis(fig[1, 1];
        dest               = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
        title              = "US Counties: Level 1 Trauma Centers and Nearby Areas",
        aspect             = DataAspect(),
        xgridvisible       = false, ygridvisible = false,
        xticksvisible      = false, yticksvisible = false,
        xticklabelsvisible = false, yticklabelsvisible = false,
    )
    # Define colors for different categories

    trauma_center_color = colorschemes[:PuBu_3][3] # Counties with trauma centers
    nearby_color = colorschemes[:PuBu_3][2]        # Counties within 50 miles of Level 1 trauma centers
    other_color = colorschemes[:PuBu_3][1]         # All other counties

    # Create color vector based on trauma center status
    colors = [df.is_trauma_center[i] == true ? trauma_center_color : 
            df.nearby[i] == true ? nearby_color : other_color 
            for i in eachindex(df.is_trauma_center)]


    # Plot all counties at once using poly! with geometry column and color vector
    poly!(ga, df.geom, color=colors, strokecolor=:white, strokewidth=0.5)
    
    return fig, trauma_center_color, nearby_color, other_color
end
