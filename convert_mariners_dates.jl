#!/usr/bin/env julia

# Simple script to convert Mariners dates to ISO format
# Usage: julia convert_mariners_dates.jl

include("src/date_converter.jl")

println("Converting Mariners dates to ISO format for 2025...")

# Convert the original file to ISO format
input_file = "data/mariners.csv"
output_file = "data/mariners_iso.csv"

# Convert dates to ISO format
df = convert_mariners_dates_to_iso(input_file, output_file, year=2025)

println("✅ Conversion complete!")
println("📁 Original file: $input_file")
println("📁 Converted file: $output_file")
println("📊 Total rows processed: $(nrow(df))")

# Show some examples
println("\n📅 Example conversions:")
original_df = CSV.read(input_file, DataFrame)
for (i, (orig, conv)) in enumerate(zip(original_df.Date[1:min(15, nrow(df))], df.Date[1:min(15, nrow(df))]))
    if orig != conv && i <= 10
        println("  $orig → $conv")
    end
end

println("\n💡 To convert the original file in place, use:")
println("   convert_mariners_dates_inplace(\"$input_file\")") 