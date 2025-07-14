using Pkg; Pkg.activate()

# Install required packages if not already installed
println("Installing required packages...")

# Add packages to the current environment
Pkg.add("DataFrames")
Pkg.add("LibPQ") 
Pkg.add("DBInterface")
Pkg.add("GeoInterface")
Pkg.add("GeometryBasics")
Pkg.add("ArchGDAL")

println("Packages installed successfully!")

# Test imports
println("Testing imports...")
try
    using DataFrames
    println("✓ DataFrames imported successfully")
catch e
    println("✗ Error importing DataFrames: ", e)
end

try
    using LibPQ
    println("✓ LibPQ imported successfully")
catch e
    println("✗ Error importing LibPQ: ", e)
end

try
    using DBInterface
    println("✓ DBInterface imported successfully")
catch e
    println("✗ Error importing DBInterface: ", e)
end

try
    using GeoInterface
    println("✓ GeoInterface imported successfully")
catch e
    println("✗ Error importing GeoInterface: ", e)
end

try
    using GeometryBasics
    println("✓ GeometryBasics imported successfully")
catch e
    println("✗ Error importing GeometryBasics: ", e)
end

try
    using ArchGDAL
    println("✓ ArchGDAL imported successfully")
catch e
    println("✗ Error importing ArchGDAL: ", e)
end

println("\nSetup complete! You can now run trauma_query.jl or trauma_query_simple.jl") 