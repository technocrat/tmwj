using DataFrames
using XLSX

"""
    get_sheet(file_name::String, sheet::Int)

Read an Excel spreadsheet and return a specific sheet as a DataFrame.

# Arguments
- `file_name::String`: Path to the Excel file to read
- `sheet::Int`: Index of the sheet to extract (1-based indexing)

# Returns
- `DataFrame`: The specified sheet converted to a DataFrame

# Examples
```julia
# Read the first sheet from an Excel file
df = get_sheet("data/myfile.xlsx", 1)

# Read the second sheet from an Excel file  
df = get_sheet("data/myfile.xlsx", 2)
```

# Notes
- Uses the XLSX.jl package to read Excel files
- Sheet indexing starts at 1 (not 0)
- Throws an error if the file doesn't exist
- Throws an error if the sheet doesn't exist (with list of available sheets)
"""
function get_sheet(file_name::String, sheet::Int)
    # Check if file exists
    if !isfile(file_name)
        throw(ArgumentError("File '$file_name' not found"))
    end
    
    spreadsheet = XLSX.readxlsx(file_name)
    
    # Get available sheet names
    available_sheets = XLSX.sheetnames(spreadsheet)
    
    # Check if the sheet exists
    if sheet < 1 || sheet > length(available_sheets)
        sheet_list = join(["$i: \"$name\"" for (i, name) in enumerate(available_sheets)], ", ")
        throw(ArgumentError("Sheet $sheet does not exist. Available sheets: $sheet_list"))
    end
    
    table = XLSX.gettable(spreadsheet[sheet])
    return DataFrame(table)
end

export get_sheet