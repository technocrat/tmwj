using DataFrames

# Test the replace functionality
day_names = ["Friday", "Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"]
test_str = "Friday Apr 4"

println("Original: '$test_str'")

# Method 1: Using a function
function remove_day_names(str)
    result = String(str)
    for day in day_names
        result = replace(result, day => "")
    end
    return result
end

println("Method 1 result: '$(remove_day_names(test_str))'")

# Method 2: Using a different approach with regex
function remove_day_names_regex(str)
    result = String(str)
    for day in day_names
        result = replace(result, Regex("\\b$day\\b") => "")
    end
    return strip(result)
end

println("Method 2 result: '$(remove_day_names_regex(test_str))'")

# Test with a DataFrame
df = DataFrame(Date = ["Friday Apr 4", "Saturday May 10", "Sunday Jun 15"])
println("\nOriginal DataFrame:")
println(df)

# Apply the function to the DataFrame
df.Date = remove_day_names_regex.(df.Date)
println("\nAfter removing day names:")
println(df) 