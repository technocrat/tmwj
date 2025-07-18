using GeoMakie, CairoMakie
using Graphs, SimpleWeightedGraphs
using GeoJSON, GeometryBasics
using Random, Statistics
using GeoDataFrames
using DataFrames
include("src/constants.jl")

state_shapefile = "data/2024_shp/cb_2024_us_state_500k.shp"
full_states = GeoDataFrames.read(state_shapefile)
conus_states = subset(full_states, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
conus_states = subset(conus_states, :STUSPS => ByRow(x -> x ∉ ["AK", "HI"]))


# Example 1: City Network with Population Thematic Mapping
function city_network_example()
    # Sample city data (longitude, latitude, population)
    cities = [
        ("New York", -74.0, 40.7, 8400000),
        ("Los Angeles", -118.2, 34.1, 3900000),
        ("Chicago", -87.6, 41.9, 2700000),
        ("Houston", -95.4, 29.8, 2300000),
        ("Phoenix", -112.1, 33.4, 1600000),
        ("Philadelphia", -75.2, 39.9, 1600000),
        ("San Antonio", -98.5, 29.4, 1500000),
        ("San Diego", -117.2, 32.7, 1400000)
    ]
    
    # Extract coordinates and populations
    lons = [city[2] for city in cities]
    lats = [city[3] for city in cities]
    pops = [city[4] for city in cities]
    names = [city[1] for city in cities]
    
    # Create a simple network based on geographic distance
    n = length(cities)
    g = SimpleWeightedGraph(n)
    
    # Add edges between cities within certain distance threshold
    for i in 1:n, j in (i+1):n
        dist = sqrt((lons[i] - lons[j])^2 + (lats[i] - lats[j])^2)
        if dist < 20  # Arbitrary distance threshold
            add_edge!(g, i, j, 1/dist)  # Weight inversely proportional to distance
        end
    end
    
    # Create the map
    fig = Figure(size = (1000, 800))
    ax = GeoAxis(fig[1, 1], dest = conus_crs)
    hidedecorations!(ax)

    poly!(ax, conus_states.geometry, color = :white, strokecolor = :lightgray, strokewidth = 0.5)
    
    # Plot network edges first (so they appear behind nodes)
    for edge in edges(g)
        src_idx, dst_idx = edge.src, edge.dst
        lines!(ax, [lons[src_idx], lons[dst_idx]], [lats[src_idx], lats[dst_idx]], 
               color = :gray, alpha = 0.6, linewidth = 2)
    end
    
    # Plot cities as points sized by population
    scatter!(ax, lons, lats, 
             markersize = sqrt.(pops) ./ 500,  # Scale marker size with population
             color = pops, 
             colormap = :viridis,
             strokewidth = 1,
             strokecolor = :white)
    
    # Add city labels
    for (i, name) in enumerate(names)
        text!(ax, lons[i], lats[i], text = name, 
              offset = (5, 5), fontsize = 10, color = :black)
    end
    
    # Colorbar(fig[1, 2], limits = (minimum(pops), maximum(pops)), 
    #          colormap = :viridis, label = "Population")
    
    return fig
end

# Example 2: Flow Map with Thematic Background
function flow_map_example()
    # Origin and destination coordinates with flow volumes
    flows = [
        (-74.0, 40.7, -118.2, 34.1, 1500),    # NYC to LA
        (-87.6, 41.9, -95.4, 29.8, 800),      # Chicago to Houston
        (-118.2, 34.1, -112.1, 33.4, 600),    # LA to Phoenix
        (-74.0, 40.7, -87.6, 41.9, 1200),     # NYC to Chicago
        (-95.4, 29.8, -118.2, 34.1, 900),     # Houston to LA
    ]
    
    # Create background thematic data (simulated temperature grid)
    lons_grid = range(-125, -65, length=50)
    lats_grid = range(25, 50, length=40)
    temp_data = [30 + 10*sin(lon/10) + 15*cos(lat/8) + 
                 5*randn() for lat in lats_grid, lon in lons_grid]
    
    fig = Figure(size = (1200, 800))
    ax = GeoAxis(fig[1, 1], dest = "+proj=laea +lat_0=40 +lon_0=-95")
    
    # Plot thematic background (temperature)
    heatmap!(ax, lons_grid, lats_grid, temp_data, 
             colormap = :RdYlBu_r, alpha = 0.7)
    
    # Plot flow lines
    for flow in flows
        lon1, lat1, lon2, lat2, volume = flow
        
        # Create curved path for flow line
        t = range(0, 1, length=20)
        # Simple arc - could be more sophisticated
        mid_lon = (lon1 + lon2) / 2
        mid_lat = (lat1 + lat2) / 2 + 3  # Add curvature
        
        path_lons = [(1-ti)^2*lon1 + 2*ti*(1-ti)*mid_lon + ti^2*lon2 for ti in t]
        path_lats = [(1-ti)^2*lat1 + 2*ti*(1-ti)*mid_lat + ti^2*lat2 for ti in t]
        
        lines!(ax, path_lons, path_lats, 
               linewidth = volume/100, 
               color = :black, 
               alpha = 0.8)
        
        # Add arrow at destination
        arrow_lon = path_lons[end-1:end]
        arrow_lat = path_lats[end-1:end]
        arrows!(ax, [arrow_lon[1]], [arrow_lat[1]], 
                [arrow_lon[2] - arrow_lon[1]], [arrow_lat[2] - arrow_lat[1]],
                arrowsize = 15, color = :black)
    end
    
    Colorbar(fig[1, 2], limits = extrema(temp_data), 
             colormap = :RdYlBu_r, label = "Temperature (°C)")
    
    return fig
end

# Example 3: Network Centrality on Geographic Map
function centrality_mapping_example()
    # Create a random spatial network
    Random.seed!(42)
    n_nodes = 20
    
    # Generate random coordinates within a bounding box
    lons = -100 .+ 20 * rand(n_nodes)
    lats = 35 .+ 10 * rand(n_nodes)
    
    # Create network based on distance and random connections
    g = SimpleGraph(n_nodes)
    for i in 1:n_nodes, j in (i+1):n_nodes
        dist = sqrt((lons[i] - lons[j])^2 + (lats[i] - lats[j])^2)
        # Higher probability of connection for closer nodes
        if rand() < exp(-dist/3)
            add_edge!(g, i, j)
        end
    end
    
    # Calculate network centrality measures
    betweenness_cent = betweenness_centrality(g)
    degree_cent = [degree(g, i) for i in 1:n_nodes]
    
    fig = Figure(size = (1200, 600))
    
    # Plot 1: Betweenness centrality
    ax1 = GeoAxis(fig[1, 1], dest = "+proj=merc", 
                  title = "Betweenness Centrality")
    
    # Draw edges
    for edge in edges(g)
        src_idx, dst_idx = edge.src, edge.dst
        lines!(ax1, [lons[src_idx], lons[dst_idx]], [lats[src_idx], lats[dst_idx]], 
               color = :lightgray, alpha = 0.5, linewidth = 1)
    end
    
    # Draw nodes colored by betweenness centrality
    scatter!(ax1, lons, lats, 
             markersize = 15 .+ 10 * betweenness_cent,
             color = betweenness_cent,
             colormap = :plasma,
             strokewidth = 1,
             strokecolor = :white)
    
    # Plot 2: Degree centrality
    ax2 = GeoAxis(fig[1, 2], dest = "+proj=merc", 
                  title = "Degree Centrality")
    
    # Draw edges
    for edge in edges(g)
        src_idx, dst_idx = edge.src, edge.dst
        lines!(ax2, [lons[src_idx], lons[dst_idx]], [lats[src_idx], lats[dst_idx]], 
               color = :lightgray, alpha = 0.5, linewidth = 1)
    end
    
    # Draw nodes colored by degree centrality
    scatter!(ax2, lons, lats, 
             markersize = 15 .+ 2 * degree_cent,
             color = degree_cent,
             colormap = :viridis,
             strokewidth = 1,
             strokecolor = :white)
    
    Colorbar(fig[1, 3], limits = extrema(betweenness_cent), 
             colormap = :plasma, label = "Betweenness")
    Colorbar(fig[1, 4], limits = extrema(degree_cent), 
             colormap = :viridis, label = "Degree")
    
    return fig
end

# Example 4: Spatial Communities Detection
function spatial_communities_example()
    # Generate clustered spatial network
    Random.seed!(123)
    
    # Create three spatial clusters
    cluster_centers = [(-95, 40), (-85, 35), (-105, 42)]
    nodes_per_cluster = 8
    
    lons = Float64[]
    lats = Float64[]
    cluster_labels = Int[]
    
    for (i, (center_lon, center_lat)) in enumerate(cluster_centers)
        for j in 1:nodes_per_cluster
            push!(lons, center_lon + 3*randn())
            push!(lats, center_lat + 2*randn())
            push!(cluster_labels, i)
        end
    end
    
    n_nodes = length(lons)
    g = SimpleGraph(n_nodes)
    
    # Add edges with higher probability within clusters
    for i in 1:n_nodes, j in (i+1):n_nodes
        dist = sqrt((lons[i] - lons[j])^2 + (lats[i] - lats[j])^2)
        same_cluster = cluster_labels[i] == cluster_labels[j]
        
        prob = same_cluster ? exp(-dist/2) : exp(-dist/8)
        if rand() < prob
            add_edge!(g, i, j)
        end
    end
    
    fig = Figure(size = (1000, 800))
    ax = GeoAxis(fig[1, 1], dest = "+proj=laea +lat_0=39 +lon_0=-95",
                 title = "Spatial Network Communities")
    
    # Color palette for clusters
    colors = [:red, :blue, :green]
    
    # Draw edges with different styles for intra/inter-cluster
    for edge in edges(g)
        src_idx, dst_idx = edge.src, edge.dst
        same_cluster = cluster_labels[src_idx] == cluster_labels[dst_idx]
        
        lines!(ax, [lons[src_idx], lons[dst_idx]], [lats[src_idx], lats[dst_idx]], 
               color = same_cluster ? :black : :gray,
               alpha = same_cluster ? 0.8 : 0.3,
               linewidth = same_cluster ? 2 : 1)
    end
    
    # Draw nodes colored by cluster
    for i in 1:length(cluster_centers)
        cluster_mask = cluster_labels .== i
        scatter!(ax, lons[cluster_mask], lats[cluster_mask],
                markersize = 12,
                color = colors[i],
                strokewidth = 2,
                strokecolor = :white,
                label = "Cluster $i")
    end
    
    axislegend(ax, position = :lt)
    
    return fig
end

# Usage examples:
fig1 = city_network_example()
fig2 = flow_map_example()
fig3 = centrality_mapping_example()
fig4 = spatial_communities_example()

# To display a figure:
# display(fig1)
