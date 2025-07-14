using Pkg; Pkg.activate()
using DataFrames
using LibPQ
using ArchGDAL

"""
    get_counties_geom(connection_string::String="host=localhost dbname=tiger")

Retrieve county geometries from the TIGER database and convert them to proper geometry objects.

# Arguments
- `connection_string::String`: PostgreSQL connection string (default: "host=localhost dbname=tiger")

# Returns
- `DataFrame`: DataFrame containing county data with proper geometry objects

# Description
This function connects to the TIGER database and retrieves county data including:
- All standard county fields (geoid, name, statefp, countyfp, etc.)
- Geometry data converted from WKB format to ArchGDAL geometry objects

The function uses ST_AsBinary() to get geometry in WKB (Well-Known Binary) format,
then converts each WKB byte array to a proper ArchGDAL geometry object.

# Example
```julia
# Get counties with default connection
counties = get_counties_geom()

# Get counties with custom connection
counties = get_counties_geom("host=myserver.com dbname=tiger user=myuser password=mypass")

# Check geometry type
println(typeof(counties.geom[1]))  # Should be ArchGDAL geometry object
```
"""
function get_counties_geom(connection_string::String="host=localhost dbname=tiger")
    # Connect to the database
    println("Connecting to database...")
    conn = LibPQ.Connection(connection_string)
    
    try
        # Query to get all county data with WKB geometry
        query = "SELECT *, ST_AsBinary(geom) as geom_wkb FROM census.counties"
        
        println("Executing query...")
        result = LibPQ.execute(conn, query)
        
        # Convert to DataFrame
        println("Converting to DataFrame...")
        df = DataFrame(result)
        
        println("Converting WKB geometries to ArchGDAL objects...")
        # Convert WKB bytes to ArchGDAL geometries
        df.geom_converted = [ArchGDAL.fromWKB(Vector{UInt8}(wkb)) for wkb in df.geom_wkb]
        
        # Remove the temporary WKB column and original string geom
        select!(df, Not(:geom))
        rename!(df, :geom_converted => :geom)
        
        println("Successfully retrieved $(nrow(df)) counties with geometry objects")
        println("Geometry type: $(typeof(df.geom[1]))")
        
        return select!(df, Cols(15,1:14))
        
    catch e
        println("Error retrieving county geometries: ", e)
        rethrow(e)
    finally
        # Close the database connection
        close(conn)
        println("Database connection closed.")
    end
end

"""
    get_counties_geom_filtered(connection_string::String="host=localhost dbname=tiger"; 
                              state_filter::Union{String, Vector{String}}=nothing,
                              county_filter::Union{String, Vector{String}}=nothing)

Retrieve county geometries with optional filtering by state or county.

# Arguments
- `connection_string::String`: PostgreSQL connection string
- `state_filter`: Filter by state FIPS code(s) (optional)
- `county_filter`: Filter by county name(s) (optional)

# Returns
- `DataFrame`: Filtered county data with proper geometry objects

# Example
```julia
# Get counties from specific states
ca_counties = get_counties_geom_filtered(state_filter="06")  # California
ny_counties = get_counties_geom_filtered(state_filter=["36", "42"])  # NY and PA

# Get specific counties
specific_counties = get_counties_geom_filtered(county_filter=["Los Angeles", "Orange"])
```
"""
function get_counties_geom_filtered(connection_string::String="host=localhost dbname=tiger"; 
                                  state_filter::Union{String, Vector{String}}=nothing,
                                  county_filter::Union{String, Vector{String}}=nothing)
    
    # Build WHERE clause based on filters
    where_clause = ""
    
    if !isnothing(state_filter)
        if state_filter isa String
            where_clause = "WHERE statefp = '$state_filter'"
        else
            state_list = join(["'$s'" for s in state_filter], ", ")
            where_clause = "WHERE statefp IN ($state_list)"
        end
    end
    
    if !isnothing(county_filter)
        if county_filter isa String
            county_condition = "name = '$county_filter'"
        else
            county_list = join(["'$c'" for c in county_filter], ", ")
            county_condition = "name IN ($county_list)"
        end
        
        if isempty(where_clause)
            where_clause = "WHERE $county_condition"
        else
            where_clause = where_clause * " AND $county_condition"
        end
    end
    
    # Connect to the database
    println("Connecting to database...")
    conn = LibPQ.Connection(connection_string)
    
    try
        # Build query with filters
        query = "SELECT *, ST_AsBinary(geom) as geom_wkb FROM census.counties $where_clause"
        
        println("Executing filtered query...")
        result = LibPQ.execute(conn, query)
        
        # Convert to DataFrame
        println("Converting to DataFrame...")
        df = DataFrame(result)
        
        if nrow(df) == 0
            println("No counties found matching the filter criteria")
            return df
        end
        
        println("Converting WKB geometries to ArchGDAL objects...")
        # Convert WKB bytes to ArchGDAL geometries
        df.geom_converted = [ArchGDAL.fromWKB(Vector{UInt8}(wkb)) for wkb in df.geom_wkb]
        
        # Remove the temporary WKB column and original string geom
        select!(df, Not(:geom))
        rename!(df, :geom_converted => :geom)
        
        println("Successfully retrieved $(nrow(df)) counties with geometry objects")
        
        return select!(df, Cols(15,1:14))
        
    catch e
        println("Error retrieving filtered county geometries: ", e)
        rethrow(e)
    finally
        # Close the database connection
        close(conn)
        println("Database connection closed.")
    end
end

# Main execution for testing
if abspath(PROGRAM_FILE) == @__FILE__
    println("Testing get_counties_geom function...")
    
    try
        # Test basic function
        counties = get_counties_geom()
        
        println("\nFirst 3 counties:")
        println(first(counties, 3))
        
        println("\nColumns: ", names(counties))
        println("Total counties: ", nrow(counties))
        
        # Test filtered function
        println("\nTesting filtered function...")
        ca_counties = get_counties_geom_filtered(state_filter="06")
        println("California counties: ", nrow(ca_counties))
        
    catch e
        println("Error during testing: ", e)
        println("\nPlease check:")
        println("1. Database connection parameters")
        println("2. Table 'census.counties' exists")
        println("3. ArchGDAL package is installed")
    end
end

# Export functions
export get_counties_geom, get_counties_geom_filtered