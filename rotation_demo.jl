using Plots
using LinearAlgebra

# Set up the plot
p = plot(
    xlims=(-2, 2), 
    ylims=(-2, 2),
    aspect_ratio=:equal,
    title="Rotation Demo: θ = π/4 (45°)",
    legend=:topright
)

# Draw coordinate axes
plot!([-2, 2], [0, 0], color=:black, linewidth=1, label="x-axis")
plot!([0, 0], [-2, 2], color=:black, linewidth=1, label="y-axis")

# Starting vector (1, 0)
start_vector = [1.0, 0.0]
plot!([0, start_vector[1]], [0, start_vector[2]], 
      color=:blue, linewidth=3, arrow=true, label="Starting vector")

# Rotation matrix for counterclockwise rotation
θ = π/4  # 45 degrees
R_ccw = [cos(θ) -sin(θ); sin(θ) cos(θ)]

# Rotation matrix for clockwise rotation (negative angle)
R_cw = [cos(-θ) -sin(-θ); sin(-θ) cos(-θ)]

# Apply rotations
end_ccw = R_ccw * start_vector
end_cw = R_cw * start_vector

# Plot the results
plot!([0, end_ccw[1]], [0, end_ccw[2]], 
      color=:red, linewidth=3, arrow=true, label="Counterclockwise (θ = π/4)")
plot!([0, end_cw[1]], [0, end_cw[2]], 
      color=:green, linewidth=3, arrow=true, label="Clockwise (θ = -π/4)")

# Add angle arcs to show rotation direction
t = range(0, θ, length=50)
arc_ccw_x = cos.(t)
arc_ccw_y = sin.(t)
plot!(arc_ccw_x, arc_ccw_y, color=:red, linewidth=2, label="", linestyle=:dash)

t_cw = range(0, -θ, length=50)
arc_cw_x = cos.(t_cw)
arc_cw_y = sin.(t_cw)
plot!(arc_cw_x, arc_cw_y, color=:green, linewidth=2, label="", linestyle=:dash)

# Add text annotations
annotate!(0.7, 0.3, text("CCW", :red, 12))
annotate!(0.7, -0.3, text("CW", :green, 12))

display(p)
savefig("rotation_demo.png")

println("Rotation Demo Results:")
println("Starting vector: [1, 0]")
println("Angle θ = π/4 = 45°")
println()
println("Counterclockwise rotation (θ = π/4):")
println("  End vector: [$(round(end_ccw[1], digits=3)), $(round(end_ccw[2], digits=3))]")
println("  This is the standard mathematical convention")
println()
println("Clockwise rotation (θ = -π/4):")
println("  End vector: [$(round(end_cw[1], digits=3)), $(round(end_cw[2], digits=3))]")
println("  This is the opposite direction")
println()
println("The key difference is in the ROTATION MATRIX, not just the angle value!") 