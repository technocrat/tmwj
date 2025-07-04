using Pkg; Pkg.activate()
using DataFrames
using LibPQ
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

"""
    create_trauma_dataframe()

Creates a DataFrame called 'trauma' by querying the TIGER database.
Joins census.counties, census.population, and census.trauma_centers on :geoid.
Adds a boolean field 'nearby' that is true if the centroid of any :geom 
is within 200 miles of the centroid of a :geoid where :center is true.

Returns:
    DataFrame: The trauma DataFrame with all joined data and the nearby field
"""
function create_trauma_dataframe()
    # Connect to the TIGER database
    println("Connecting to TIGER database...")
    conn = LibPQ.Connection("dbname=tiger")
    
    try
        # SQL query to join the tables and calculate spatial proximity
        query = """
        SELECT 
            c.geoid,
            c.name as county_name,
            c.statefp,
            c.countyfp,
            p.value as population,
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
        
        println("Executing query...")
        result = LibPQ.execute(conn, query)
        
        # Convert the result to a DataFrame
        println("Converting results to DataFrame...")
        trauma = DataFrame(result)
        
        # Convert geometry string to proper geometry object if it exists
        if hasproperty(trauma, :geom) && !isempty(trauma.geom)
            println("Converting geometry strings to geometry objects...")
            # Convert WKB/WKT strings to geometry objects
            trauma.geom = [parse_geometry(geom_str) for geom_str in trauma.geom]
        end
        
        println("Query completed successfully!")
        println("DataFrame 'trauma' created with $(nrow(trauma)) rows and $(ncol(trauma)) columns")
        println("Columns: ", names(trauma))
        
        # Print some summary statistics
        if hasproperty(trauma, :nearby)
            nearby_count = count(trauma.nearby)
            total_count = nrow(trauma)
            println("\nSummary:")
            println("- Total counties: $total_count")
            println("- Counties within 200 miles of trauma centers: $nearby_count")
            println("- Percentage nearby: $(round(nearby_count/total_count * 100, digits=1))%")
        end
        
        return trauma
        
    catch e
        println("Error executing query: ", e)
        rethrow(e)
    finally
        # Close the database connection
        close(conn)
        println("Database connection closed.")
    end
end

# Alternative query with different table structure assumptions
function create_trauma_dataframe_alternative()
    conn = LibPQ.Connection("dbname=tiger")
    
    try
        # Simpler query that might work with different table structures
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
        
        println("Executing alternative query...")
        result = LibPQ.execute(conn, query)
        trauma = DataFrame(result)
        
        println("Alternative query completed!")
        println("DataFrame 'trauma' created with $(nrow(trauma)) rows")
        
        # Convert geometry string to proper geometry object if it exists
        if hasproperty(trauma, :geom) && !isempty(trauma.geom)
            println("Converting geometry strings to geometry objects...")
            trauma.geom = [parse_geometry(geom_str) for geom_str in trauma.geom]
        end
        
        return trauma
        
    catch e
        println("Error with alternative query: ", e)
        rethrow(e)
    finally
        close(conn)
    end
end

# Main execution
if abspath(PROGRAM_FILE) == @__FILE__
    println("Creating trauma DataFrame...")
    
    try
        # Try the main query first
        trauma = create_trauma_dataframe()
    catch e
        println("Main query failed, trying alternative...")
        println("Error: ", e)
        
        try
            # Try the alternative query
            trauma = create_trauma_dataframe_alternative()
        catch e2
            println("Alternative query also failed.")
            println("Error: ", e2)
            println("\nPlease check:")
            println("1. Database connection parameters")
            println("2. Table names and schema")
            println("3. Column names in your tables")
            println("4. PostgreSQL PostGIS extension is installed")
            error("Failed to create trauma DataFrame")
        end
    end
    
    # Display first few rows
    println("\nFirst 5 rows of trauma DataFrame:")
    println(first(trauma, 5))
    
    # Save to CSV if needed
    # CSV.write("trauma_data.csv", trauma)
    # println("\nData saved to trauma_data.csv")
end

# Export the function for use in other scripts
export create_trauma_dataframe, create_trauma_dataframe_alternative 