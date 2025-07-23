month_map = Dict(
    "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4,
    "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8,
    "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12
)

test_str = "Sep 17"
parts = split(strip(test_str), " ")
month_str = parts[1]
day_str = parts[2]

println("month_str: '$month_str'")
println("day_str: '$day_str'")
println("month_map[month_str]: $(month_map[month_str])")
println("typeof(month_map[month_str]): $(typeof(month_map[month_str]))")

# Test the comprehension
month = [month_map[m] for m in [month_str] if haskey(month_map, m)]
println("month from comprehension: $month")
println("typeof(month): $(typeof(month))")
println("typeof(month[1]): $(typeof(month[1]))")

# Test the Date creation
try
    date = Date(2025, month[1], parse(Int, day_str))
    println("Date created successfully: $date")
catch e
    println("Error creating Date: $e")
end 