using DataFrames
using CSV

# Load the data
df = CSV.read("city_counties.csv", DataFrame)

# Method 1: Using coalesce and proper string extraction (FIXED)
df.state = coalesce.(match.(r"[,][ ]([A-Za-z]+)$", df.city) .|> x -> isnothing(x) ? "" : x[1], "")

# Method 2: More explicit approach
df.state2 = [let m = match(r"[,][ ]([A-Za-z]+)$", city)
                isnothing(m) ? "" : m[1]
            end for city in df.city]

# Method 3: Using replace with capture groups
df.state3 = replace.(df.city, r"^.*[,][ ]([A-Za-z]+)$" => s"\1")

# Method 4: Using split (simpler approach)
df.state4 = [let parts = split(city, ", ")
                length(parts) > 1 ? parts[end] : ""
            end for city in df.city]

# Display results
println("Original data:")
println(first(df[:, [:city, :state, :state2, :state3, :state4]], 10))

println("\nAll methods should produce the same result:")
println("Method 1 (coalesce): ", df.state[1:5])
println("Method 2 (explicit): ", df.state2[1:5])
println("Method 3 (capture): ", df.state3[1:5])
println("Method 4 (split): ", df.state4[1:5])

# Verify all methods give the same result
println("\nVerification - all methods produce identical results:")
println("Methods 1 & 2 match: ", all(df.state .== df.state2))
println("Methods 2 & 3 match: ", all(df.state2 .== df.state3))
println("Methods 3 & 4 match: ", all(df.state3 .== df.state4)) 