using VoronoiDelaunay
using CairoMakie

# Example 1: Basic Voronoi Diagram
function create_voronoi_example()
    # Generate random points (VoronoiDelaunay requires points in [1,2] x [1,2])
    n_points = 20
    points = [VoronoiDelaunay.Point(1 + rand(), 1 + rand()) for _ in 1:n_points]
    
    # Create Delaunay triangulation (prerequisite for Voronoi)
    tess = DelaunayTessellation2D(n_points)
    push!(tess, points)
    
    # Create figure and axis
    fig = Figure()
    ax = Axis(fig[1, 1], title="Voronoi Diagram", limits=(1, 2, 1, 2))
    
    # Plot Voronoi edges
    for edge in voronoiedges(tess)
        x1, y1 = VoronoiDelaunay.getx(VoronoiDelaunay.geta(edge)), VoronoiDelaunay.gety(VoronoiDelaunay.geta(edge))
        x2, y2 = VoronoiDelaunay.getx(VoronoiDelaunay.getb(edge)), VoronoiDelaunay.gety(VoronoiDelaunay.getb(edge))
        lines!(ax, [x1, x2], [y1, y2], color=:blue, linewidth=1)
    end
    
    # Plot generator points
    x_coords = [VoronoiDelaunay.getx(p) for p in points]
    y_coords = [VoronoiDelaunay.gety(p) for p in points]
    scatter!(ax, x_coords, y_coords, color=:red, markersize=8)
    
    return fig
end

# Example 2: Delaunay Triangulation
function create_delaunay_example()
    # Generate random points
    n_points = 15
    points = [VoronoiDelaunay.Point(1 + rand(), 1 + rand()) for _ in 1:n_points]
    
    # Create Delaunay triangulation
    tess = DelaunayTessellation2D(n_points)
    push!(tess, points)
    
    # Create figure and axis
    fig = Figure()
    ax = Axis(fig[1, 1], title="Delaunay Triangulation", limits=(1, 2, 1, 2))
    
    # Plot triangulation edges
    for edge in delaunayedges(tess)
        x1, y1 = VoronoiDelaunay.getx(VoronoiDelaunay.geta(edge)), VoronoiDelaunay.gety(VoronoiDelaunay.geta(edge))
        x2, y2 = VoronoiDelaunay.getx(VoronoiDelaunay.getb(edge)), VoronoiDelaunay.gety(VoronoiDelaunay.getb(edge))
        lines!(ax, [x1, x2], [y1, y2], color=:green, linewidth=1)
    end
    
    # Plot points
    x_coords = [VoronoiDelaunay.getx(p) for p in points]
    y_coords = [VoronoiDelaunay.gety(p) for p in points]
    scatter!(ax, x_coords, y_coords, color=:red, markersize=8)
    
    return fig
end

# Example 3: Thematic Mapping Application - Service Area Analysis
function service_area_mapping()
    # Simulate hospital locations (scaled to [1,2] x [1,2])
    hospitals = [
        VoronoiDelaunay.Point(1.2, 1.3),  # Hospital A
        VoronoiDelaunay.Point(1.7, 1.4),  # Hospital B
        VoronoiDelaunay.Point(1.5, 1.8),  # Hospital C
        VoronoiDelaunay.Point(1.3, 1.7),  # Hospital D
        VoronoiDelaunay.Point(1.6, 1.2)   # Hospital E
    ]
    
    # Create tessellation
    tess = DelaunayTessellation2D(length(hospitals))
    push!(tess, hospitals)
    
    # Create figure and axis
    fig = Figure()
    ax = Axis(fig[1, 1], title="Hospital Service Areas", limits=(1, 2, 1, 2))
    
    # Plot Voronoi boundaries
    for edge in voronoiedges(tess)
        x1, y1 = VoronoiDelaunay.getx(VoronoiDelaunay.geta(edge)), VoronoiDelaunay.gety(VoronoiDelaunay.geta(edge))
        x2, y2 = VoronoiDelaunay.getx(VoronoiDelaunay.getb(edge)), VoronoiDelaunay.gety(VoronoiDelaunay.getb(edge))
        lines!(ax, [x1, x2], [y1, y2], color=:black, linewidth=2)
    end
    
    # Plot hospitals with labels
    x_coords = [VoronoiDelaunay.getx(p) for p in hospitals]
    y_coords = [VoronoiDelaunay.gety(p) for p in hospitals]
    scatter!(ax, x_coords, y_coords, color=:red, markersize=12, marker=:star5)
    
    # Add hospital labels
    for (i, hospital) in enumerate(hospitals)
        text!(ax, VoronoiDelaunay.getx(hospital), VoronoiDelaunay.gety(hospital) + 0.05, 
              text="H$i", fontsize=12, align=(:center, :bottom))
    end
    
    return fig
end

# Example 4: Interpolation using Delaunay triangulation
function interpolation_example()
    # Create sample data points with elevation values
    sample_points = [
        (VoronoiDelaunay.Point(1.2, 1.3), 100.0),  # (point, elevation)
        (VoronoiDelaunay.Point(1.8, 1.4), 150.0),
        (VoronoiDelaunay.Point(1.5, 1.8), 200.0),
        (VoronoiDelaunay.Point(1.3, 1.7), 180.0),
        (VoronoiDelaunay.Point(1.6, 1.2), 120.0),
        (VoronoiDelaunay.Point(1.4, 1.5), 160.0),
        (VoronoiDelaunay.Point(1.7, 1.7), 190.0)
    ]
    
    points = [p[1] for p in sample_points]
    elevations = [p[2] for p in sample_points]
    
    # Create Delaunay triangulation
    tess = DelaunayTessellation2D(length(points))
    push!(tess, points)
    
    # Create figure and axis
    fig = Figure()
    ax = Axis(fig[1, 1], title="Elevation Interpolation via Delaunay", limits=(1, 2, 1, 2))
    
    # Plot triangulation
    for edge in delaunayedges(tess)
        x1, y1 = VoronoiDelaunay.getx(VoronoiDelaunay.geta(edge)), VoronoiDelaunay.gety(VoronoiDelaunay.geta(edge))
        x2, y2 = VoronoiDelaunay.getx(VoronoiDelaunay.getb(edge)), VoronoiDelaunay.gety(VoronoiDelaunay.getb(edge))
        lines!(ax, [x1, x2], [y1, y2], color=:gray, linewidth=1)
    end
    
    # Plot sample points with elevation colors
    x_coords = [VoronoiDelaunay.getx(p) for p in points]
    y_coords = [VoronoiDelaunay.gety(p) for p in points]
    scatter!(ax, x_coords, y_coords, color=elevations, colormap=:terrain, markersize=12)
    
    # Add elevation labels
    for (i, (point, elev)) in enumerate(sample_points)
        text!(ax, VoronoiDelaunay.getx(point), VoronoiDelaunay.gety(point) + 0.05, 
              text="$(Int(elev))m", fontsize=10, align=(:center, :bottom))
    end
    
    return fig
end

# Generate all examples
println("Creating Voronoi and Delaunay examples...")

# Create figures
fig1 = create_voronoi_example()
fig2 = create_delaunay_example()
fig3 = service_area_mapping()
fig4 = interpolation_example()

# Display individual figures
# display(fig1)
# display(fig2)
# display(fig3)
# display(fig4)

# Alternative: Create a combined figure
function create_combined_figure()
    fig = Figure(size=(800, 600))
    
    # You would need to modify the functions above to accept an axis parameter
    # for a proper combined layout. For now, display them individually.
    
    return fig
end
f = create_combined_figure()
display(f)