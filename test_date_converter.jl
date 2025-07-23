using DataFrames
include("src/date_converter.jl")

# Test the updated function
test_df = DataFrame(Date = ["Friday Apr 4", "Saturday May 10", "Sunday Jun 15", "Monday Jul 20"])

println("Original DataFrame:")
println(test_df)

# Convert dates
result_df = convert_mariners_dates_to_iso(test_df, 2025)

println("\nConverted DataFrame:")
println(result_df) 