# Trauma DataFrame Query

This directory contains Julia scripts to create a DataFrame called `trauma` by querying a PostgreSQL database with TIGER/Line data.

## Overview

The scripts perform the following operations:
1. Connect to a PostgreSQL database containing TIGER/Line data
2. Join three tables: `census.counties`, `census.population`, and `census.trauma_centers` on the `:geoid` field
3. Calculate a boolean field `:nearby` that is `true` if the centroid of any `:geom` is within 200 miles of the centroid of a `:geoid` where `:center` is `true`
4. Return the result as a Julia DataFrame

## Files

- `trauma_query.jl` - Comprehensive version with error handling and alternative queries (uses DBInterface)
- `trauma_query_simple.jl` - Simplified version for quick testing (uses DBInterface)
- `trauma_query_libpq.jl` - Alternative version using LibPQ directly (no DBInterface dependency)
- `setup_trauma_query.jl` - Setup script to install required packages
- `TRAUMA_QUERY_README.md` - This documentation file

## Prerequisites

### 1. Database Setup
You need a PostgreSQL database with:
- PostGIS extension installed
- TIGER/Line data loaded into the following tables:
  - `census.counties` (with columns: `geoid`, `name`, `geom`)
  - `census.county_population` (with columns: `geoid`, `value`)
  - `census.trauma_centers` (with columns: `geoid`, `center`)

### 2. Julia Dependencies
Make sure you have the following packages installed:
```julia
using Pkg
Pkg.add(["DataFrames", "LibPQ", "DBInterface"])
```

Or run the setup script:
```bash
julia setup_trauma_query.jl
```

## Usage

### Option 1: Simple Version (with DBInterface)
1. Edit `trauma_query_simple.jl` to update the database connection string
2. Run the script:
```bash
julia trauma_query_simple.jl
```

### Option 2: Comprehensive Version (with DBInterface)
1. Edit `trauma_query.jl` to update the database connection string
2. Run the script:
```bash
julia trauma_query.jl
```

### Option 3: LibPQ Direct Version (no DBInterface dependency)
1. Edit `trauma_query_libpq.jl` to update the database connection string
2. Run the script:
```bash
julia trauma_query_libpq.jl
```

### Option 4: Use as a Module
```julia
include("trauma_query_libpq.jl")  # or trauma_query.jl
trauma = create_trauma_dataframe()
```

## Database Connection

Update the connection string in the script to match your database setup:

```julia
# Example connection strings:
conn = LibPQ.Connection("dbname=tiger")  # Local database
conn = LibPQ.Connection("dbname=tiger host=localhost user=username password=password")
conn = LibPQ.Connection("dbname=tiger host=your-server.com port=5432 user=username password=password")
```

## SQL Query Details

The main query performs the following operations:

1. **Spatial Join**: Uses PostGIS functions to calculate distances between county centroids and trauma center centroids
2. **Distance Calculation**: Uses `ST_DWithin()` with geography type for accurate distance calculations (200 miles = 321,868.8 meters)
3. **Boolean Logic**: Creates a `nearby` field that is `true` if any trauma center with `center = true` is within 200 miles

### Key PostGIS Functions Used:
- `ST_Centroid(geom)` - Calculates the center point of a geometry
- `ST_DWithin(geom1, geom2, distance)` - Checks if geometries are within a specified distance
- `::geography` - Casts geometry to geography type for accurate distance calculations

## Expected Output

The resulting DataFrame will have columns similar to:
- `geoid` - Geographic identifier
- `county_name` - Name of the county
- `population` - Population data
- `is_trauma_center` - Boolean indicating if this county has a trauma center
- `nearby` - Boolean indicating if within 200 miles of a trauma center
- `geom` - Geometry data

## Troubleshooting

### Common Issues:

1. **Connection Error**: Check database connection parameters
2. **Table Not Found**: Verify table names and schema
3. **Column Not Found**: Check column names in your tables
4. **PostGIS Error**: Ensure PostGIS extension is installed
5. **Permission Error**: Check database user permissions
6. **DBInterface Import Error**: Use `trauma_query_libpq.jl` instead, which doesn't require DBInterface

### Debugging:
- The comprehensive version includes error handling and alternative queries
- Check the console output for detailed error messages
- Verify your database schema matches the expected structure

## Customization

You can modify the scripts to:
- Change the distance threshold (currently 200 miles)
- Add additional columns from the joined tables
- Modify the spatial calculation logic
- Add additional filtering conditions

## Example Output

```
Creating trauma DataFrame...
Connecting to TIGER database...
Executing query...
Converting results to DataFrame...
Query completed successfully!
DataFrame 'trauma' created with 3142 rows and 10 columns
Columns: [:geoid, :county_name, :state_fips, :county_fips, :population, :is_trauma_center, :nearby, :geom]

Summary:
- Total counties: 3142
- Counties within 200 miles of trauma centers: 2891
- Percentage nearby: 92.0% 