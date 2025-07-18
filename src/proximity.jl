using Distances
using NearestNeighbors
using CairoMakie
using LinearAlgebra

# Example 1: Different Distance Metrics for Proximity Analysis
function compare_distance_metrics()
    # Service facility locations
    facilities = [
        [1.2, 1.3],  # Hospital A
        [1.7, 1.4],  # Hospital B  
        [1.5, 1.8],  # Hospital C
        [1.3, 1.7]   # Hospital D
    ]
    
    # Create a grid of query points
    x_range = range(1.0, 2.0, length=50)
    y_range = range(1.0, 2.0, length=50)
    grid_points = [[x, y] for x in x_range, y in y_range]
    
    # Different distance metrics
    metrics = [
        (Euclidean(), "Euclidean Distance"),
        (Cityblock(), "Manhattan Distance"), 
        (Chebyshev(), "Chebyshev Distance"),
        (Minkowski(3.0), "Minkowski Distance (p=3)")
    ]
    
    fig = Figure(size=(1000, 800))
    
    for (i, (metric, title)) in enumerate(metrics)
        ax = Axis(fig[div(i-1, 2)+1, mod(i-1, 2)+1], 
                 title=title, limits=(1, 2, 1, 2))
        
        # Build KDTree for fast nearest neighbor queries
        facility_matrix = hcat(facilities...)
        kdtree = KDTree(facility_matrix, metric)
        
        # Create proximity map
        proximity_map = zeros(Int, length(x_range), length(y_range))
        
        for (xi, x) in enumerate(x_range)
            for (yi, y) in enumerate(y_range)
                query_point = [x, y]
                nearest_idx, _ = knn(kdtree, query_point, 1)
                proximity_map[xi, yi] = nearest_idx[1]
            end
        end
        
        # Plot proximity regions with different colors
        heatmap!(ax, x_range, y_range, proximity_map', 
                colormap=:Set1_4, alpha=0.6)
        
        # Plot facility locations
        x_coords = [f[1] for f in facilities]
        y_coords = [f[2] for f in facilities] 
        scatter!(ax, x_coords, y_coords, color=:black, markersize=15, marker=:star5)
        
        # Add facility labels
        for (j, facility) in enumerate(facilities)
            text!(ax, facility[1], facility[2] + 0.05, 
                  text="F$j", fontsize=12, align=(:center, :bottom))
        end
    end
    
    return fig
end

# Example 2: Weighted Proximity (Power Diagram Simulation)
function weighted_proximity_analysis()
    # Facilities with different capacities/weights
    facilities = [
        ([1.2, 1.3], 50),   # Small clinic
        ([1.7, 1.4], 200),  # Large hospital  
        ([1.5, 1.8], 100),  # Medium hospital
        ([1.3, 1.7], 75)    # Medium clinic
    ]
    
    locations = [f[1] for f in facilities]
    weights = [f[2] for f in facilities]
    
    # Normalize weights to create "effective radius"
    max_weight = maximum(weights)
    normalized_weights = weights ./ max_weight
    
    # Create grid for analysis
    x_range = range(1.0, 2.0, length=100)
    y_range = range(1.0, 2.0, length=100)
    
    # Custom weighted distance function
    function weighted_distance(point, facility_location, weight)
        euclidean_dist = norm(point - facility_location)
        # Larger weight = more attractive = effectively shorter distance
        return euclidean_dist / weight
    end
    
    # Calculate weighted proximity map
    proximity_map = zeros(Int, length(x_range), length(y_range))
    distance_map = zeros(Float64, length(x_range), length(y_range))
    
    for (xi, x) in enumerate(x_range)
        for (yi, y) in enumerate(y_range)
            query_point = [x, y]
            
            # Find facility with minimum weighted distance
            min_distance = Inf
            closest_facility = 1
            
            for (i, (location, weight)) in enumerate(facilities)
                dist = weighted_distance(query_point, location, normalized_weights[i])
                if dist < min_distance
                    min_distance = dist
                    closest_facility = i
                end
            end
            
            proximity_map[xi, yi] = closest_facility
            distance_map[xi, yi] = min_distance
        end
    end
    
    fig = Figure(size=(1200, 500))
    
    # Plot 1: Weighted proximity regions
    ax1 = Axis(fig[1, 1], title="Weighted Proximity Regions", limits=(1, 2, 1, 2))
    heatmap!(ax1, x_range, y_range, proximity_map', colormap=:Set1_4, alpha=0.7)
    
    # Plot facilities with size proportional to weight
    x_coords = [f[1][1] for f in facilities]
    y_coords = [f[1][2] for f in facilities]
    marker_sizes = [w/5 for w in weights]  # Scale for visibility
    
    scatter!(ax1, x_coords, y_coords, markersize=marker_sizes, 
             color=:black, marker=:star5)
    
    # Add labels with weights
    for (i, ((x, y), weight)) in enumerate(facilities)
        text!(ax1, x, y + 0.05, text="F$i ($(weight))", 
              fontsize=10, align=(:center, :bottom))
    end
    
    # Plot 2: Distance contours
    ax2 = Axis(fig[1, 2], title="Weighted Distance Field", limits=(1, 2, 1, 2))
    contourf!(ax2, x_range, y_range, distance_map', levels=20, colormap=:viridis)
    scatter!(ax2, x_coords, y_coords, markersize=marker_sizes, 
             color=:red, marker=:star5)
    
    return fig
end

# Example 3: Anisotropic Distance (Direction-Dependent)
function anisotropic_proximity()
    # Simulate terrain where movement is faster east-west than north-south
    # (e.g., mountain ridges running north-south)
    
    facilities = [
        [1.2, 1.3],
        [1.8, 1.4], 
        [1.5, 1.8]
    ]
    
    # Anisotropic distance function
    function anisotropic_distance(p1, p2, x_factor=1.0, y_factor=2.0)
        dx = (p2[1] - p1[1]) * x_factor
        dy = (p2[2] - p1[2]) * y_factor
        return sqrt(dx^2 + dy^2)
    end
    
    x_range = range(1.0, 2.0, length=80)
    y_range = range(1.0, 2.0, length=80)
    
    # Calculate anisotropic proximity
    proximity_map = zeros(Int, length(x_range), length(y_range))
    
    for (xi, x) in enumerate(x_range)
        for (yi, y) in enumerate(y_range)
            query_point = [x, y]
            
            min_distance = Inf
            closest_facility = 1
            
            for (i, facility) in enumerate(facilities)
                # Movement is 2x harder in y-direction (north-south)
                dist = anisotropic_distance(query_point, facility, 1.0, 2.0)
                if dist < min_distance
                    min_distance = dist
                    closest_facility = i
                end
            end
            
            proximity_map[xi, yi] = closest_facility
        end
    end
    
    fig = Figure(size=(800, 600))
    
    # Compare isotropic vs anisotropic
    ax1 = Axis(fig[1, 1], title="Standard Euclidean", limits=(1, 2, 1, 2))
    ax2 = Axis(fig[1, 2], title="Anisotropic (Y-direction 2x harder)", limits=(1, 2, 1, 2))
    
    # Standard Euclidean for comparison
    facility_matrix = hcat(facilities...)
    kdtree = KDTree(facility_matrix, Euclidean())
    euclidean_map = zeros(Int, length(x_range), length(y_range))
    
    for (xi, x) in enumerate(x_range)
        for (yi, y) in enumerate(y_range)
            query_point = [x, y]
            nearest_idx, _ = knn(kdtree, query_point, 1)
            euclidean_map[xi, yi] = nearest_idx[1]
        end
    end
    
    heatmap!(ax1, x_range, y_range, euclidean_map', colormap=:Set1_3, alpha=0.7)
    heatmap!(ax2, x_range, y_range, proximity_map', colormap=:Set1_3, alpha=0.7)
    
    # Plot facilities on both
    x_coords = [f[1] for f in facilities]
    y_coords = [f[2] for f in facilities]
    
    scatter!(ax1, x_coords, y_coords, color=:black, markersize=12, marker=:star5)
    scatter!(ax2, x_coords, y_coords, color=:black, markersize=12, marker=:star5)
    
    return fig
end

# Example 4: Network Distance Simulation
function network_distance_proximity()
    # Simulate a simple road network where direct paths aren't always available
    
    facilities = [
        [1.2, 1.2],  # Southwest
        [1.8, 1.8]   # Northeast
    ]
    
    # Simulate that there's a barrier (river, mountain) from (1.5, 1.0) to (1.5, 2.0)
    # requiring detour around the barrier
    
    function network_distance(p1, p2)
        # If path crosses the barrier at x=1.5, add detour cost
        if (p1[1] < 1.5 && p2[1] > 1.5) || (p1[1] > 1.5 && p2[1] < 1.5)
            # Must go around the barrier - add detour penalty
            detour_distance = abs(p1[2] - 1.5) + abs(p2[2] - 1.5) + 0.5
            return norm(p2 - p1) + detour_distance
        else
            return norm(p2 - p1)
        end
    end
    
    x_range = range(1.0, 2.0, length=60)
    y_range = range(1.0, 2.0, length=60)
    
    proximity_map = zeros(Int, length(x_range), length(y_range))
    
    for (xi, x) in enumerate(x_range)
        for (yi, y) in enumerate(y_range)
            query_point = [x, y]
            
            distances = [network_distance(query_point, facility) for facility in facilities]
            closest_facility = argmin(distances)
            proximity_map[xi, yi] = closest_facility
        end
    end
    
    fig = Figure(size=(600, 600))
    ax = Axis(fig[1, 1], title="Network Distance with Barrier", limits=(1, 2, 1, 2))
    
    heatmap!(ax, x_range, y_range, proximity_map', colormap=[:lightblue, :lightcoral], alpha=0.7)
    
    # Draw the barrier
    lines!(ax, [1.5, 1.5], [1.0, 2.0], color=:black, linewidth=4, label="Barrier")
    
    # Plot facilities
    x_coords = [f[1] for f in facilities]
    y_coords = [f[2] for f in facilities]
    scatter!(ax, x_coords, y_coords, color=:black, markersize=15, marker=:star5)
    
    text!(ax, facilities[1][1], facilities[1][2] - 0.05, text="F1", 
          fontsize=12, align=(:center, :top))
    text!(ax, facilities[2][1], facilities[2][2] + 0.05, text="F2", 
          fontsize=12, align=(:center, :bottom))
    
    return fig
end

# Run examples
println("Creating custom proximity analysis examples...")

# Generate all examples
fig1 = compare_distance_metrics()
fig2 = weighted_proximity_analysis() 
fig3 = anisotropic_proximity()
fig4 = network_distance_proximity()

# Display
display(fig1)
display(fig2) 
display(fig3)
display(fig4)