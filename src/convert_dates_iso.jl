
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
function convert_mariners_dates_to_iso(input_file::String, output_file::String; year::Int=2025)
    # Read the CSV file
    df = CSV.read(input_file, DataFrame)
    
    # Check if Date column exists
    if !hasproperty(df, :Date)
        error("CSV file does not contain a 'Date' column")
    end
    
    # Month mapping
    month_map = Dict(
        "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4,
        "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8,
        "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12
    )
    
    # Function to convert a single date string
    function convert_date_string(date_str)
        # Convert to String if needed
        date_str = String(date_str)
        
        # Skip if it's a preview or other non-date entry
        if contains(date_str, "preview") || contains(date_str, "Game Preview")
            return date_str
        end
        
        # Parse the date string (e.g., "Friday Apr 4")
        parts = split(strip(date_str), " ")
        
        if length(parts) >= 3
            # Extract month and day
            month_str = parts[2]
            day_str = parts[3]
            
            # Convert month abbreviation to number
            if haskey(month_map, month_str)
                month = month_map[month_str]
                
                # Convert day to integer
                day = parse(Int, day_str)
                
                # Create Date object and format as ISO
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
    
    # Convert all dates
    println("Converting dates to ISO format for year $year...")
    df.Date = convert_date_string.(df.Date)
    
    # Write the converted data to output file
    CSV.write(output_file, df)
    println("Converted data saved to: $output_file")
    
    return df
end
