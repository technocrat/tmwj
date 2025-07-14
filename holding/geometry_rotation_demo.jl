using StaticArrays
using LinearAlgebra
using Plots

# Define a simple geometry (a triangle)
triangle = [
    SVector(0.0, 0.0),    # bottom left
    SVector(1.0, 0.0),    # bottom right  
    SVector(0.5, 1.0),    # top
    SVector(0.0, 0.0)     # close the triangle
]

# Function to apply affine transformation
function apply_transform(points, A, b)
    return [A * p + b for p in points]
end

# Function to create rotation matrix (similar to Angle2d)
function rotation_matrix(θ)
    return [cos(θ) -sin(θ); sin(θ) cos(θ)]
end

# Set up the plot
p = plot(
    xlims=(-2, 2), 
    ylims=(-2, 2),
    aspect_ratio=:equal,
    title="Geometry Rotation Demo",
    legend=:topright
)

# Original triangle
original_x = [p[1] for p in triangle]
original_y = [p[2] for p in triangle]
plot!(original_x, original_y, color=:black, linewidth=3, label="Original", marker=:circle)

# Test different angles
angles = [π/4, π/2, π, -π/4, -π/2]  # 45°, 90°, 180°, -45°, -90°
colors = [:red, :blue, :green, :orange, :purple]
labels = ["45° CCW", "90° CCW", "180° CCW", "45° CW", "90° CW"]

for (i, θ) in enumerate(angles)
    # Create transformation
    R = rotation_matrix(θ)
    S = Diagonal(SVector(0.5, 0.5))  # Scale down a bit
    A = S * R
    b = SVector(0.0, 0.0)  # No translation
    
    # Apply transformation
    transformed = apply_transform(triangle, A, b)
    
    # Plot transformed geometry
    trans_x = [p[1] for p in transformed]
    trans_y = [p[2] for p in transformed]
    plot!(trans_x, trans_y, color=colors[i], linewidth=2, 
          label=labels[i], marker=:circle, markersize=3)
end

# Add coordinate axes
plot!([-2, 2], [0, 0], color=:gray, linewidth=1, label="", linestyle=:dash)
plot!([0, 0], [-2, 2], color=:gray, linewidth=1, label="", linestyle=:dash)

display(p)
savefig("geometry_rotation_demo.png")

println("Geometry Rotation Demo Results:")
println("Original triangle vertices:")
for (i, p) in enumerate(triangle[1:3])
    println("  Point $i: [$(round(p[1], digits=2)), $(round(p[2], digits=2))]")
end

println("\nTransformed triangles with different angles:")
for (i, θ) in enumerate(angles)
    R = rotation_matrix(θ)
    S = Diagonal(SVector(0.5, 0.5))
    A = S * R
    b = SVector(0.0, 0.0)
    
    transformed = apply_transform(triangle[1:3], A, b)
    println("\n$(labels[i]) (θ = $(round(θ*180/π, digits=1))°):")
    for (j, p) in enumerate(transformed)
        println("  Point $j: [$(round(p[1], digits=3)), $(round(p[2], digits=3))]")
    end
end

println("\nKey observation: The geometry changes dramatically with different angles!") 