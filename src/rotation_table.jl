using Printf

function show_rotation_table(n::Int=50)
    println("Use this table to determine the rotation angle for the inset function.")
    println("Angle Table: θ = ±π/denominator (+ = counterclockwise, - = clockwise)")
    println("=" ^ 81)
    println("Denominator | +π/denom (rad) | +π/denom (deg) | -π/denom (rad) | -π/denom (deg) | Direction")
    println("-" ^ 81)

    # Generate table for denominators from 1 to n
    for denom in 1:n
        θ_pos = π / denom
        θ_neg = -π / denom
        θ_pos_degrees = θ_pos * 180 / π
        θ_neg_degrees = θ_neg * 180 / π
        
        direction_note = denom == 4 ? "π/4 = 45° (CCW)" : ""
        @printf("%11d | %14.4f | %13.2f° | %14.4f | %13.2f° | %s\n", 
                denom, θ_pos, θ_pos_degrees, θ_neg, θ_neg_degrees, direction_note);
    end;

    print("\n" * "=" ^ 81 * "\n" * "Note:\n • Positive angles (+π/denom): Counterclockwise rotation\n • Negative angles (-π/denom): Clockwise rotation\n • θ = π/4 = 45° is counterclockwise\n • θ = -π/4 = -45° is clockwise")
end

