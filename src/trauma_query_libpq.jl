using Pkg; Pkg.activate()
using DataFrames
using LibPQ
using ArchGDAL

"""
    create_trauma_dataframe(connection_string::String="host=localhost dbname=tiger", distance_miles::Int=100)

Creates a DataFrame called 'trauma' by querying the TIGER database.
Joins census.counties, census.population, and census.trauma_centers on :geoid.
Adds a boolean field 'nearby' that is true if the centroid of any :geom 
is within the specified distance of the centroid of a :geoid where :center is true.

# Arguments
- `connection_string::String`: PostgreSQL connection string (default: "host=localhost dbname=tiger")
- `distance_miles::Int`: Distance in miles to check for nearby trauma centers (default: 100)

Returns:
    DataFrame: The trauma DataFrame with all joined data and the nearby field
"""
function create_trauma_dataframe(distance_miles::Int)
    # Connect to the TIGER database
    println("Connecting to TIGER database...")
    conn = LibPQ.Connection("host=localhost dbname=tiger")
# function create_trauma_dataframe(connection_string::String="host=localhost dbname=tiger", distance_miles::Int=100)
#     # Connect to the TIGER database
#     println("Connecting to TIGER database...")
#     conn = LibPQ.Connection(connection_string)
    
    try
        # Convert miles to meters (1 mile = 1609.344 meters)
        distance_meters = distance_miles * 1609.344
        
        # SQL query to join the tables and calculate spatial proximity
        # Use ST_AsBinary() to get geometry in WKB format
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
                        $distance_meters
                    )
                ) THEN true 
                ELSE false 
            END as nearby,
            ST_AsBinary(c.geom) as geom_wkb
        FROM census.counties c
        LEFT JOIN census.county_population p ON c.geoid = p.geoid
        LEFT JOIN census.trauma_centers tc ON c.geoid = tc.geoid
        ORDER BY c.geoid;
        """
        
        println("Executing query with distance threshold of $distance_miles miles...")
        result = LibPQ.execute(conn, query)
        
        # Convert the result to a DataFrame
        println("Converting results to DataFrame...")
        trauma = DataFrame(result)
        
        # Convert WKB bytes to ArchGDAL geometry objects
        if hasproperty(trauma, :geom_wkb) && !isempty(trauma.geom_wkb)
            println("Converting WKB geometries to ArchGDAL objects...")
            trauma.geom_converted = [ArchGDAL.fromWKB(Vector{UInt8}(wkb)) for wkb in trauma.geom_wkb]
            
            # Remove the temporary WKB column
            select!(trauma, Not(:geom_wkb))
            rename!(trauma, :geom_converted => :geom)
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
            println("- Counties within $distance_miles miles of trauma centers: $nearby_count")
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
function create_trauma_dataframe_alternative(connection_string::String="host=localhost dbname=tiger", distance_miles::Int=25)
    conn = LibPQ.Connection(connection_string)
    
    try
        # Convert miles to meters (1 mile = 1609.344 meters)
        distance_meters = distance_miles * 1609.344
        
        # Simpler query that might work with different table structures
        # Use ST_AsBinary() to get geometry in WKB format
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
                        $distance_meters
                    )
                ) THEN true 
                ELSE false 
            END as nearby,
            ST_AsBinary(c.geom) as geom_wkb
        FROM census.counties c
        LEFT JOIN census.county_population p ON c.geoid = p.geoid
        LEFT JOIN census.trauma_centers tc ON c.geoid = tc.geoid
        ORDER BY c.geoid;
        """
        
        println("Executing alternative query with distance threshold of $distance_miles miles...")
        result = LibPQ.execute(conn, query)
        trauma = DataFrame(result)
        
        println("Alternative query completed!")
        println("DataFrame 'trauma' created with $(nrow(trauma)) rows")
        
        # Convert WKB bytes to ArchGDAL geometry objects
        if hasproperty(trauma, :geom_wkb) && !isempty(trauma.geom_wkb)
            println("Converting WKB geometries to ArchGDAL objects...")
            trauma.geom_converted = [ArchGDAL.fromWKB(Vector{UInt8}(wkb)) for wkb in trauma.geom_wkb]
            
            # Remove the temporary WKB column
            select!(trauma, Not(:geom_wkb))
            rename!(trauma, :geom_converted => :geom)
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
    
    # You can specify the distance here
    distance_miles = 50  # Change this value as needed
    
    try
        # Try the main query first
        trauma = create_trauma_dataframe(distance_miles=distance_miles)
    catch e
        println("Main query failed, trying alternative...")
        println("Error: ", e)
        
        try
            # Try the alternative query
            trauma = create_trauma_dataframe_alternative(distance_miles=distance_miles)
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
