"""
    align_table_string(table_string::String) -> String

Right-align the data strings after newlines to match the alignment of the header strings before newlines.

# Arguments
- `table_string::String`: A table string (typically from PrettyTables) with alignment issues

# Returns
- `String`: The table string with properly aligned data

# Example
```julia
# Input table string with misaligned data:
# " Total Counties  Trauma Centers  Nearby Counties  Other Counties\n 3,126           157             1,126            1,843\n"
# 
# Output table string with aligned data:
# " Total Counties  Trauma Centers  Nearby Counties  Other Counties\n    3,126           157           1,126          1,843\n"
```
"""
function align_table_string(table_string::String)
    # Split the string into lines
    lines = split(table_string, '\n')
    
    if length(lines) < 2
        return table_string  # Return as-is if not enough lines
    end
    
    # Get the header line (first line)
    header_line = lines[1]
    
    # Find the column boundaries by detecting where words start
    # Look for patterns like " Word" (space followed by non-space)
    column_starts = Int[]
    column_ends = Int[]
    
    # Find the start of each column (space followed by non-space)
    for i in 2:length(header_line)
        if header_line[i-1] == ' ' && header_line[i] != ' '
            push!(column_starts, i)
        end
    end
    
    # Find the end of each column (non-space followed by space, or end of line)
    for i in 1:length(header_line)-1
        if header_line[i] != ' ' && header_line[i+1] == ' '
            push!(column_ends, i)
        end
    end
    
    # Handle the last column (ends at end of line)
    if !isempty(column_starts) && length(column_ends) < length(column_starts)
        push!(column_ends, length(header_line))
    end
    
    # If we have data lines, align them
    aligned_lines = [header_line]  # Keep header as-is
    
    for line_idx in 2:length(lines)
        data_line = lines[line_idx]
        
        # Skip empty lines
        if isempty(strip(data_line))
            push!(aligned_lines, data_line)
            continue
        end
        
        # Split the data line into values (split on multiple spaces)
        data_values = filter(!isempty, split(data_line, r"\s+"))
        
        # Create aligned data line
        aligned_data_line = ""
        
        for (col_idx, start_pos) in enumerate(column_starts)
            if col_idx <= length(column_ends) && col_idx <= length(data_values)
                value = data_values[col_idx]
                end_pos = column_ends[col_idx]
                col_width = end_pos - start_pos + 1
                
                # Right-align the value within the column width
                if length(value) <= col_width
                    padding = col_width - length(value)
                    aligned_data_line *= " "^padding * value
                else
                    # Truncate if value is too long
                    aligned_data_line *= value[1:col_width]
                end
            end
        end
        
        push!(aligned_lines, aligned_data_line)
    end
    
    # Join the lines back together
    return join(aligned_lines, '\n')
end

"""
    align_table_string_improved(table_string::String) -> String

Improved version that handles edge cases better and preserves original spacing.

# Arguments
- `table_string::String`: A table string (typically from PrettyTables) with alignment issues

# Returns
- `String`: The table string with properly aligned data
"""
function align_table_string_improved(table_string::String)
    # Split the string into lines
    lines = split(table_string, '\n')
    
    if length(lines) < 2
        return table_string
    end
    
    # Get the header line
    header_line = lines[1]
    
    # Find column boundaries by looking for transitions from space to non-space
    column_boundaries = Int[]
    prev_char = ' '
    
    for (i, char) in enumerate(header_line)
        if prev_char == ' ' && char != ' '
            push!(column_boundaries, i)
        end
        prev_char = char
    end
    
    # Add the end position
    push!(column_boundaries, length(header_line) + 1)
    
    # Process data lines
    aligned_lines = [header_line]
    
    for line_idx in 2:length(lines)
        data_line = lines[line_idx]
        
        if isempty(strip(data_line))
            push!(aligned_lines, data_line)
            continue
        end
        
        # Extract data values (split on whitespace and filter empty)
        data_values = filter(!isempty, split(data_line, r"\s+"))
        
        # Build aligned line
        aligned_line = ""
        
        for col_idx in 1:(length(column_boundaries) - 1)
            start_pos = column_boundaries[col_idx]
            end_pos = column_boundaries[col_idx + 1] - 1
            col_width = end_pos - start_pos + 1
            
            # Get the value for this column
            value = col_idx <= length(data_values) ? data_values[col_idx] : ""
            
            # Right-align the value within the column width
            if length(value) <= col_width
                # Pad with spaces to right-align
                padding = col_width - length(value)
                aligned_line *= " "^padding * value
            else
                # Truncate if value is too long
                aligned_line *= value[1:col_width]
            end
        end
        
        push!(aligned_lines, aligned_line)
    end
    
    return join(aligned_lines, '\n')
end

"""
    align_table_string_simple(table_string::String) -> String

Simple and robust version that correctly handles PrettyTables output format.

# Arguments
- `table_string::String`: A table string from PrettyTables with alignment issues

# Returns
- `String`: The table string with properly aligned data
"""
function align_table_string_simple(table_string::String)
    # Split the string into lines
    lines = split(table_string, '\n')
    
    if length(lines) < 2
        return table_string
    end
    
    # Get the header line
    header_line = lines[1]
    
    # Find the positions where each column starts
    # In PrettyTables format, columns are separated by multiple spaces
    # We need to find where each word starts after spaces
    column_positions = Int[]
    
    # Find the start of each word (non-space character after spaces)
    in_word = false
    for (i, char) in enumerate(header_line)
        if char != ' ' && !in_word
            push!(column_positions, i)
            in_word = true
        elseif char == ' '
            in_word = false
        end
    end
    
    # If no columns found, return original
    if isempty(column_positions)
        return table_string
    end
    
    # Process data lines
    aligned_lines = [header_line]
    
    for line_idx in 2:length(lines)
        data_line = lines[line_idx]
        
        if isempty(strip(data_line))
            push!(aligned_lines, data_line)
            continue
        end
        
        # Extract data values
        data_values = filter(!isempty, split(data_line, r"\s+"))
        
        # Build aligned line
        aligned_line = ""
        
        for (col_idx, start_pos) in enumerate(column_positions)
            # Calculate column width
            col_width = if col_idx < length(column_positions)
                # Width is from start of this column to start of next column
                next_start = column_positions[col_idx + 1]
                next_start - start_pos
            else
                # Last column - use remaining width
                length(header_line) - start_pos + 1
            end
            
            # Get the value for this column
            value = col_idx <= length(data_values) ? data_values[col_idx] : ""
            
            # Right-align the value within the column width
            if length(value) <= col_width
                padding = col_width - length(value)
                aligned_line *= " "^padding * value
            else
                # Truncate if value is too long
                aligned_line *= value[1:col_width]
            end
        end
        
        push!(aligned_lines, aligned_line)
    end
    
    return join(aligned_lines, '\n')
end

"""
    right_align_table_data(table_string::String) -> String

Right-align the data in a table string to match the header alignment.
This is the main function you should use.

# Arguments
- `table_string::String`: A table string from PrettyTables with misaligned data

# Returns
- `String`: The table string with properly right-aligned data

# Example
```julia
# Input: " Total Counties  Trauma Centers  Nearby Counties  Other Counties\n 3,126           157             1,126            1,843\n"
# Output: " Total Counties  Trauma Centers  Nearby Counties  Other Counties\n    3,126           157           1,126          1,843\n"
```
"""
function right_align_table_data(table_string::String)
    lines = split(table_string, '\n')
    if length(lines) < 2
        return table_string
    end
    header = lines[1]

    # Find column start and end indices by runs of 2+ spaces
    col_starts = [1]
    col_ends = Int[]
    i = 1
    while i <= length(header)
        # Find next run of 2+ spaces
        if i < length(header) && header[i] == ' ' && header[i+1] == ' '
            # End of current column
            push!(col_ends, i)
            # Find where the spaces end
            j = i+1
            while j <= length(header) && header[j] == ' '
                j += 1
            end
            if j <= length(header)
                push!(col_starts, j)
            end
            i = j
        else
            i += 1
        end
    end
    # Last column ends at end of line
    push!(col_ends, length(header))

    # Now align data lines
    result_lines = [header]
    for line in lines[2:end]
        if isempty(strip(line))
            push!(result_lines, line)
            continue
        end
        # Split data values (on runs of 2+ spaces)
        data_values = filter(!isempty, split(line, r"\s{2,}"))
        aligned_line = ""
        for col_idx in 1:length(col_starts)
            start_pos = col_starts[col_idx]
            end_pos = col_ends[col_idx]
            col_width = end_pos - start_pos + 1
            value = col_idx <= length(data_values) ? strip(data_values[col_idx]) : ""
            # Right-align value in column
            if length(value) <= col_width
                padding = col_width - length(value)
                aligned_line *= " "^padding * value
            else
                aligned_line *= value[1:col_width]
            end
        end
        push!(result_lines, aligned_line)
    end
    return join(result_lines, '\n')
end

# Example usage and testing
if abspath(PROGRAM_FILE) == @__FILE__
    test_table = " Total Counties  Trauma Centers  Nearby Counties  Other Counties\n 3,126           157             1,126            1,843\n"
    println("Original table:")
    println(test_table)
    println()
    println("Right-aligned table:")
    aligned = right_align_table_data(test_table)
    println(aligned)
    println()
    test_table2 = " Name    Age  City     Salary\n John    25   New York 50000\n Mary    30   Boston   60000\n"
    println("Original table 2:")
    println(test_table2)
    println()
    println("Right-aligned table 2:")
    aligned2 = right_align_table_data(test_table2)
    println(aligned2)
end 