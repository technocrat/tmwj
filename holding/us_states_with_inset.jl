using CairoMakie
using GeoDataFrames
using DataFramesMeta
import GeometryOps as GO
using GeoInterface
using Proj

# Define the Albers Equal Area projection for continental US
const AEA_CONUS = "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"

# Define projections for Alaska and Hawaii (centered on their regions)
const AEA_ALASKA = "+proj=aea +lat_1=55 +lat_2=65 +lat_0=50 +lon_0=-154 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
const AEA_HAWAII = "+proj=aea +lat_1=8 +lat_2=18 +lat_0=13 +lon_0=-157 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"

# Function to reproject geometry using Proj.jl
function reproject_geom_proj(geom, source_proj4, target_proj4)
    # Create transformation
    trans = Proj.Transformation(source_proj4, target_proj4, always_xy=true)
    
    # Transform the geometry
    return GO.transform(geom) do point
        x, y = trans(point[1], point[2])
        return (x, y)
    end
end

# Improved fit_to_bbox function that works with projected coordinates
function fit_to_bbox_projected(geom, target_min, target_max; rotation_degrees=0)
    # Get geometry bounds
    extent = GeoInterface.extent(geom)
    min_pt = (extent.X[1], extent.Y[1])
    max_pt = (extent.X[2], extent.Y[2])
    
    # Compute scale factors
    scale_x = (target_max[1] - target_min[1]) / (max_pt[1] - min_pt[1])
    scale_y = (target_max[2] - target_min[2]) / (max_pt[2] - min_pt[2])
    scale = min(scale_x, scale_y)  # uniform scaling
    
    # Compute center-based transformation
    center_src = ((min_pt[1] + max_pt[1]) / 2, (min_pt[2] + max_pt[2]) / 2)
    center_tgt = ((target_min[1] + target_max[1]) / 2, (target_min[2] + target_max[2]) / 2)
    
    # Convert rotation to radians
    rotation_rad = rotation_degrees * π / 180
    
    # Apply transformation: translate to origin, scale, rotate, translate to target
    function transform_point(p)
        # Translate to origin and scale
        x, y = (p[1] - center_src[1]) * scale, (p[2] - center_src[2]) * scale
        
        # Apply rotation if specified
        if rotation_degrees != 0
            x_rot = x * cos(rotation_rad) - y * sin(rotation_rad)
            y_rot = x * sin(rotation_rad) + y * cos(rotation_rad)
            x, y = x_rot, y_rot
        end
        
        # Translate to target position
        return (x + center_tgt[1], y + center_tgt[2])
    end
    
    # Apply to all points in geometry
    return GO.transform(transform_point, geom)
end

# Main plotting function
function plot_us_with_insets(states_gdf, alaska_gdf, hawaii_gdf; zoom_to_insets=false)
    # Separate continental US states
    conus_states = @chain states_gdf begin
        @rsubset(:STUSPS ∉ ["AK", "HI", "PR", "VI", "GU", "MP", "AS"])
    end
    
    # Define source CRS (NAD83 geographic)
    source_crs = "+proj=longlat +datum=NAD83 +no_defs"
    
    # Reproject continental US to Albers Equal Area
    conus_geoms_projected = [reproject_geom_proj(g, source_crs, AEA_CONUS) for g in conus_states.geometry]
    
    # Reproject Alaska
    ak_geom = alaska_gdf.geometry[1]  # assuming single geometry
    # First project Alaska using its own Albers projection
    ak_geom_alaska_aea = reproject_geom_proj(ak_geom, source_crs, AEA_ALASKA)
    # Then reproject to continental US projection for consistent units
    ak_geom_conus_proj = reproject_geom_proj(ak_geom, source_crs, AEA_CONUS)
    
    # Reproject Hawaii
    hi_geom = hawaii_gdf.geometry[1]  # assuming single multipolygon
    
    # Filter to just the main inhabited islands (first 10 polygons)
    # Get the component polygons
    hi_polygons = GI.getgeom(hi_geom)
    
    # Take only the first 10 polygons (the inhabited islands)
    inhabited_polygons = collect(Iterators.take(hi_polygons, 10))
    
    # Create a new MultiPolygon with just the inhabited islands
    hi_geom_filtered = GI.MultiPolygon(inhabited_polygons)
    
    # First project Hawaii using its own Albers projection
    hi_geom_hawaii_aea = reproject_geom_proj(hi_geom_filtered, source_crs, AEA_HAWAII)
    # Then reproject to continental US projection
    hi_geom_conus_proj = reproject_geom_proj(hi_geom_filtered, source_crs, AEA_CONUS)
    
    # Get extent of continental US for positioning
    # Combine all conus geometries to get full extent
    all_conus_points = []
    for geom in conus_geoms_projected
        ext = GeoInterface.extent(geom)
        push!(all_conus_points, (ext.X[1], ext.Y[1]))
        push!(all_conus_points, (ext.X[2], ext.Y[2]))
    end
    
    conus_min_x = minimum(p[1] for p in all_conus_points)
    conus_max_x = maximum(p[1] for p in all_conus_points)
    conus_min_y = minimum(p[2] for p in all_conus_points)
    conus_max_y = maximum(p[2] for p in all_conus_points)
    
    conus_width = conus_max_x - conus_min_x
    conus_height = conus_max_y - conus_min_y
    
    # Calculate a visual reference line for inset placement
    # Instead of using the absolute bottom (Key West), use a line roughly at the 
    # bottom of the southwestern states (approximately 31-32°N)
    # This is roughly 7-8 degrees north of Key West, or about 15-20% up from the bottom
    visual_reference_y = conus_min_y + conus_height * 0.15  # Adjust this percentage as needed
    
    # Debug output
    # println("Continental US bounds - X: $conus_min_x to $conus_max_x, Y: $conus_min_y to $conus_max_y")
    # println("Visual reference line (SW states bottom): $visual_reference_y")
    # println("Difference from true bottom: $(visual_reference_y - conus_min_y) meters")
    
    # Define target bounding boxes (in projected meters)
    # Alaska: even smaller for conventional layout
    alaska_width = conus_width * 0.15  # Smaller than before
    alaska_height = conus_height * 0.15  # Smaller than before
    # Position Alaska further left with tighter gap
    alaska_x_offset = -conus_width * -0.05  # more negative to bring closer to Hawaii
    # Use gap from visual reference line (SW states) not from Key West
    alaska_y_gap = 100000  # 100km gap from visual reference line
    alaska_target_min = (conus_min_x + alaska_x_offset, visual_reference_y - alaska_height - alaska_y_gap)
    alaska_target_max = (conus_min_x + alaska_x_offset + alaska_width, visual_reference_y - alaska_y_gap)
    
    # Debug output
    println("Alaska Y gap: $alaska_y_gap")
    println("Alaska height: $alaska_height")
    println("Visual reference Y (SW states): $visual_reference_y")
    println("Alaska top edge: $(visual_reference_y - alaska_y_gap)")
    println("Alaska bottom edge: $(visual_reference_y - alaska_height - alaska_y_gap)")
    println("Distance from visual reference to Alaska top: $(alaska_y_gap)")
    println("Alaska bounds - X: $(alaska_target_min[1]) to $(alaska_target_max[1]), Y: $(alaska_target_min[2]) to $(alaska_target_max[2])")
    
    # Hawaii: make much bigger now that we only have inhabited islands
    hawaii_width = conus_width * 0.45  # Much bigger - was 0.4
    hawaii_height = conus_height * 0.45  # Much bigger
    hawaii_x_center = conus_min_x + conus_width * 0.3  # Position
    hawaii_y_offset = 0  # Keep at same level as Alaska
    hawaii_target_min = (hawaii_x_center - hawaii_width/2, alaska_target_min[2] + hawaii_y_offset)
    hawaii_target_max = (hawaii_x_center + hawaii_width/2, alaska_target_max[2] + hawaii_y_offset)
    
    # Apply transformations to Alaska and Hawaii
    ak_transformed = fit_to_bbox_projected(ak_geom_conus_proj, alaska_target_min, alaska_target_max)
    hi_transformed = fit_to_bbox_projected(hi_geom_conus_proj, hawaii_target_min, hawaii_target_max, rotation_degrees=30)
    
    # Create the plot
    fig = Figure(size = (1200, 800), backgroundcolor = :white)
    # background color is transparent to hide the bounding box lines, when not :white or transparent
    ax = Axis(fig[1, 1], aspect = DataAspect(), backgroundcolor = :transparent)
    
    # Plot continental US
    for geom in conus_geoms_projected
        poly!(ax, geom, color = :white, strokecolor = :black, strokewidth = 0.5)
    end
    
    # Plot Alaska
    poly!(ax, ak_transformed, color = :white, strokecolor = :black, strokewidth = 0.5)
    
    # Plot Hawaii
    poly!(ax, hi_transformed, color = :white, strokecolor = :black, strokewidth = 0.5)
    
    # Add bounding boxes for insets (optional)
    alaska_bbox_points = [
        Point2(alaska_target_min...),
        Point2(alaska_target_max[1], alaska_target_min[2]),
        Point2(alaska_target_max...),
        Point2(alaska_target_min[1], alaska_target_max[2]),
        Point2(alaska_target_min...)
    ]
    
    hawaii_bbox_points = [
        Point2(hawaii_target_min...),
        Point2(hawaii_target_max[1], hawaii_target_min[2]),
        Point2(hawaii_target_max...),
        Point2(hawaii_target_min[1], hawaii_target_max[2]),
        Point2(hawaii_target_min...)
    ]
    # line drawing of bounding boxes for insets suppressed with :white color
    lines!(ax, alaska_bbox_points, color = :white, linewidth = 1, linestyle = :dash)
    lines!(ax, hawaii_bbox_points, color = :white, linewidth = 1, linestyle = :dash)
    
    # Add labels
    text!(ax, "Alaska and Hawaii not to scale", position = (alaska_target_min[1] + alaska_width/2, alaska_target_max[2] + 50000),
          align = (:center, :bottom), fontsize = 14, font = "Arial")
    text!(ax, "", position = (hawaii_x_center, hawaii_target_max[2] + 50000),
          align = (:center, :bottom), fontsize = 14, font = "Arial")
    
    # Set axis limits based on zoom preference
    if zoom_to_insets
        # Zoom to show just the bottom portion with insets
        plot_min_y = min(alaska_target_min[2], hawaii_target_min[2]) - 50000
        plot_max_y = conus_min_y + conus_height * 0.3  # Show only bottom 30% of continental US
        # println("Zoomed view: focusing on insets and southern states")
    else
        # Show full map
        plot_min_y = min(alaska_target_min[2], hawaii_target_min[2]) - 50000
        plot_max_y = conus_max_y + 50000
    end
    
    plot_min_x = min(alaska_target_min[1], conus_min_x) - 50000
    plot_max_x = max(hawaii_target_max[1], conus_max_x) + 50000
    
    xlims!(ax, plot_min_x, plot_max_x)
    ylims!(ax, plot_min_y, plot_max_y)
    
    # Debug output
    # println("Plot Y limits: $plot_min_y to $plot_max_y (range: $(plot_max_y - plot_min_y))")
    # println("Plot X limits: $plot_min_x to $plot_max_x (range: $(plot_max_x - plot_min_x))")
    # println("Continental US height: $conus_height")
    # println("Y-axis spans $(round((plot_max_y - plot_min_y)/1000)) km")
    # println("Expected Y-span should be roughly $(round((conus_height + alaska_height + alaska_y_gap + 100000)/1000)) km")
    
    # Remove axis decorations
    hidedecorations!(ax)
    hidespines!(ax)
    
    return fig
end

# Example usage:
# Assuming you have loaded your shapefiles into GeoDataFrames
states = GeoDataFrames.read("data/2024_shp/cb_2024_us_state_500k.shp")
alaska = @rsubset(states, :STUSPS == "AK")
hawaii = @rsubset(states, :STUSPS == "HI")

fig = plot_us_with_insets(states, alaska, hawaii)
# save("us_map_with_insets.png", fig