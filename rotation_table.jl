using Printf

println("Angle Table: θ = ±π/denominator")
println("=" ^ 60)
println("Denominator | +π/denom (rad) | +π/denom (deg) | -π/denom (rad) | -π/denom (deg) | Direction")
println("-" ^ 60)

# Generate table for denominators from 1 to 12
for denom in 1:12
    θ_pos = π / denom
    θ_neg = -π / denom
    θ_pos_degrees = θ_pos * 180 / π
    θ_neg_degrees = θ_neg * 180 / π
    
    direction_note = denom == 4 ? "π/4 = 45° (CCW)" : ""
    @printf("%11d | %14.4f | %15.2f° | %14.4f | %15.2f° | %s\n", 
            denom, θ_pos, θ_pos_degrees, θ_neg, θ_neg_degrees, direction_note)
end

println("\n" * "=" ^ 60)
println("Note:")
println("• Positive angles (+π/denom): Counterclockwise rotation")
println("• Negative angles (-π/denom): Clockwise rotation")
println("• θ = π/4 = 45° is counterclockwise")
println("• θ = -π/4 = -45° is clockwise") 