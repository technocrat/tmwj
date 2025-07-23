using CSV
using DataFrames
using Dates

"""
    convert_mariners_dates_to_iso(input_file::String, output_file::String; year::Int=2025)

Convert dates in the Mariners CSV file from "Friday Apr 4" format to ISO format "2025-04-04".

# Arguments
- `input_file::String`: Path to the input CSV file (e.g., "data/mariners.csv")
- `output_file::String`: Path to the output CSV file
- `year::Int`: Year to use for the ISO dates (default: 2025)

# Example
```julia
convert_mariners_dates_to_iso("data/mariners.csv", "data/mariners_iso.csv")
```

# Notes
- Assumes the date column is named "Date"
- Handles various day formats (e.g., "Friday", "Monday", etc.)
- Handles various month abbreviations (e.g., "Mar", "Apr", "May", etc.)
- Preserves all other columns in the CSV
"""
function convert_mariners_dates_to_iso(road_trip::DataFrame, year::Int=2025)
    df = road_trip
    if !hasproperty(df, :Date)
        error("dataframe does not contain a 'Date' column.")
    end
    
    # Remove day names first
    day_names = ["Friday", "Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"]
    function remove_day_names(str)
        result = String(str)
        for day in day_names
            result = replace(result, Regex("\\b$day\\b") => "")
        end
        return strip(result)
    end
    df.Date = remove_day_names.(df.Date)
    
    month_map = Dict(
        "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4,
        "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8,
        "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12
    )
    
    function convert_date_string(date_str)
        date_str = String(date_str)
        # Now the format should be "Apr 4" (no leading space)
        parts = split(strip(date_str), " ")
        if length(parts) >= 2
            month_str = parts[1]
            day_str = parts[2]
            
            # Use comprehension to replace month abbreviation with numeric value
            month = [month_map[m] for m in [month_str] if haskey(month_map, m)]
            
            if !isempty(month)
                month = month[1]  # Get the first (and only) value
                day = parse(Int, day_str)
                try
                    date = Date(year, month, day)
                    return Dates.format(date, "yyyy-mm-dd")
                catch e
                    println("Warning: Could not parse date '$date_str': $e")
                    return date_str
                end
            else
                println("Warning: Unknown month abbreviation '$month_str' in '$date_str'")
                return date_str
            end
        else
            println("Warning: Could not parse date format '$date_str'")
            return date_str
        end
    end
    
    df.Date = convert_date_string.(df.Date)
    return df
end
