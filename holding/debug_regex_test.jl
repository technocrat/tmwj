using Pkg; Pkg.activate()  # Activate the project environment
using DataFrames
using CSV
using GeoDataFrames

# Load a small sample of the data
println("Loading data...")
df = CSV.read("data/Consumer_Airfare_Report__Table_1a_-_All_U.S._Airport_Pair_Markets.csv", DataFrame)

# Select only the columns we need
select!(df, :Geocoded_City1, :Geocoded_City2, :passengers, :city1, :city2)

println("Data types:")
println("city1 type: ", typeof(df.city1))
println("city2 type: ", typeof(df.city2))

# Test the regex pattern
println("\n=== Testing regex pattern ===")
test_string = "Washington, DC (Metropolitan Area)"
println("Test string: '$test_string'")
println("Regex pattern: r\" \\(Metropolitan Area\\)\"")
println("Matches: ", occursin(r" \(Metropolitan Area\)", test_string))

# Try different approaches
println("\n=== Testing different replacement approaches ===")

# Approach 1: Direct replace! (original approach)
println("Approach 1: Direct replace!")
df1 = copy(df)
replace!(df1.city1, r" \(Metropolitan Area\)" => "")
remaining1 = filter(x -> occursin("Metropolitan", x), df1.city1)
println("Remaining Metropolitan in city1: ", length(remaining1))

# Approach 2: Convert to regular Vector first
println("\nApproach 2: Convert to Vector first")
df2 = copy(df)
df2.city1 = Vector{String}(df2.city1)
df2.city2 = Vector{String}(df2.city2)
replace!(df2.city1, r" \(Metropolitan Area\)" => "")
replace!(df2.city2, r" \(Metropolitan Area\)" => "")
remaining2 = filter(x -> occursin("Metropolitan", x), df2.city1)
println("Remaining Metropolitan in city1: ", length(remaining2))

# Approach 3: Using broadcasting
println("\nApproach 3: Using broadcasting")
df3 = copy(df)
df3.city1 = replace.(df3.city1, r" \(Metropolitan Area\)" => "")
df3.city2 = replace.(df3.city2, r" \(Metropolitan Area\)" => "")
remaining3 = filter(x -> occursin("Metropolitan", x), df3.city1)
println("Remaining Metropolitan in city1: ", length(remaining3))

# Approach 4: Manual loop
println("\nApproach 4: Manual loop")
df4 = copy(df)
for i in eachindex(df4.city1)
    df4.city1[i] = replace(df4.city1[i], r" \(Metropolitan Area\)" => "")
end
for i in eachindex(df4.city2)
    df4.city2[i] = replace(df4.city2[i], r" \(Metropolitan Area\)" => "")
end
remaining4 = filter(x -> occursin("Metropolitan", x), df4.city1)
println("Remaining Metropolitan in city1: ", length(remaining4))

# Show results
println("\n=== Results ===")
println("Approach 1 (direct replace!): ", length(remaining1), " remaining")
println("Approach 2 (convert to Vector): ", length(remaining2), " remaining")
println("Approach 3 (broadcasting): ", length(remaining3), " remaining")
println("Approach 4 (manual loop): ", length(remaining4), " remaining")

# Show sample results from the working approach
if length(remaining4) == 0
    println("\n✓ Approach 4 (manual loop) worked!")
    println("Sample cleaned city1 values:")
    sample_cleaned = first(filter(x -> !isempty(x), df4.city1), 5)
    println(sample_cleaned)
end 