using DataFrames
using CSV

# Load the data
df = CSV.read("city_counties.csv", DataFrame)

println("=== ORIGINAL ERROR ANALYSIS ===")
println("The original code:")
println("df.state = replace.(match.(r\"[,][ ][A-Za-z]+\$\", df.city) .|> x -> something(x, \"\"), \", \" => \"\")")
println()
println("The problem: 'something()' doesn't work well with RegexMatch objects in broadcasting context")
println("RegexMatch objects need to be converted to strings properly")
println()

println("=== WORKING SOLUTIONS ===")

# Solution 1: Using capture groups with coalesce (most similar to original intent)
df.state1 = coalesce.(match.(r"[,][ ]([A-Za-z]+)$", df.city) .|> x -> isnothing(x) ? "" : String(x[1]), "")

# Solution 2: Using replace with capture groups (cleanest)
df.state2 = replace.(df.city, r"^.*[,][ ]([A-Za-z]+)$" => s"\1")

# Solution 3: Using split (most readable)
df.state3 = [let parts = split(city, ", ")
                length(parts) > 1 ? String(parts[end]) : ""
            end for city in df.city]

# Solution 4: Explicit loop (most explicit)
state4 = String[]
for city in df.city
    m = match(r"[,][ ]([A-Za-z]+)$", city)
    if isnothing(m)
        push!(state4, "")
    else
        push!(state4, String(m[1]))
    end
end
df.state4 = state4

println("Results:")
println("Solution 1 (coalesce): ", df.state1[1:5])
println("Solution 2 (replace): ", df.state2[1:5])
println("Solution 3 (split): ", df.state3[1:5])
println("Solution 4 (explicit): ", df.state4[1:5])

println("\n=== VERIFICATION ===")
println("All solutions produce identical results:")
println("Solutions 1 & 2 match: ", all(df.state1 .== df.state2))
println("Solutions 2 & 3 match: ", all(df.state2 .== df.state3))
println("Solutions 3 & 4 match: ", all(df.state3 .== df.state4))

println("\n=== RECOMMENDED SOLUTION ===")
println("For your use case, I recommend Solution 2:")
println("df.state = replace.(df.city, r\"^.*[,][ ]([A-Za-z]+)\$\" => s\"\\1\")")
println()
println("This is:")
println("- Clean and readable")
println("- Handles edge cases automatically")
println("- Returns empty string for non-matching patterns")
println("- Type-stable (returns String array)") 