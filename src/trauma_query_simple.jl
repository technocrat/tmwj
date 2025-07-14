using Pkg; Pkg.activate()
using DataFrames
using LibPQ
using DBInterface
using GeoInterface
using GeometryBasics

"""
    parse_geometry(geom_str::Union{String, Missing})

Parse a geometry string from PostGIS into a proper geometry object.
Handles WKB, WKT, and other common PostGIS geometry formats.
"""
function parse_geometry(geom_str::Union{String, Missing})
    if ismissing(geom_str) || isempty(geom_str)
        return missing
    end
    
    try
        # Try to parse as WKB hex string first
        if startswith(geom_str, "\\x") || all(c -> c in "0123456789abcdefABCDEF", geom_str)
            # This is likely a WKB hex string
            return GeoInterface.read(geom_str)
        else
            # Try to parse as WKT
            return GeoInterface.read(geom_str)
        end
    catch e
        println("Warning: Could not parse geometry: $geom_str")
        println("Error: $e")
        return missing
    end
end

# Simple function to create the trauma DataFrame
function create_trauma_dataframe()
    # Connect to your database - modify connection string as needed
    conn = LibPQ.Connection("dbname=tiger host=localhost user=your_username password=your_password")
    
    # SQL query to join tables and calculate spatial proximity
    query = """
    SELECT 
        c.geoid,
        c.name as county_name,
        p.population,
        tc.center as is_trauma_center,
                    CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM census.trauma_centers tc2
                    JOIN census.counties tc_county ON tc2.geoid = tc_county.geoid
                    WHERE tc2.center = true 
                    AND ST_DWithin(
                        ST_Centroid(c.geom)::geography, 
                        ST_Centroid(tc_county.geom)::geography, 
                        321868.8  -- 200 miles in meters
                    )
                ) THEN true 
                ELSE false 
            END as nearby,
        c.geom
            FROM census.counties c
        LEFT JOIN census.county_population p ON c.geoid = p.geoid
        LEFT JOIN census.trauma_centers tc ON c.geoid = tc.geoid
        ORDER BY c.geoid;
    """
    
    # Execute query and create DataFrame
    result = DBInterface.execute(conn, query)
    trauma = DataFrame(result)
    
    # Convert geometry string to proper geometry object if it exists
    if hasproperty(trauma, :geom) && !isempty(trauma.geom)
        println("Converting geometry strings to geometry objects...")
        trauma.geom = [parse_geometry(geom_str) for geom_str in trauma.geom]
    end
    
    # Close connection
    close(conn)
    
    return trauma
end

# Execute the function
trauma = create_trauma_dataframe()

# Display results
println("Trauma DataFrame created with $(nrow(trauma)) rows")
println("Columns: ", names(trauma))
println("\nFirst 5 rows:")
println(first(trauma, 5))

# Summary statistics
if hasproperty(trauma, :nearby)
    nearby_count = count(trauma.nearby)
    total_count = nrow(trauma)
    println("\nSummary:")
    println("- Total counties: $total_count")
    println("- Counties within 200 miles of trauma centers: $nearby_count")
    println("- Percentage nearby: $(round(nearby_count/total_count * 100, digits=1))%")
end 