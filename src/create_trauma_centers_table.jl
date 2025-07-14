# create trauma centers table

# Create and populate trauma_centers table in tiger.census schema
conn = LibPQ.Connection("dbname=tiger")

# Drop table if it exists
execute(conn, "DROP TABLE IF EXISTS census.trauma_centers")

# Create table
execute(conn, """
    CREATE TABLE census.trauma_centers (
        geoid VARCHAR(5),
        center BOOLEAN
    )
""")

# Insert data
for row in eachrow(trauma_centers)
    execute(conn, """
        INSERT INTO census.trauma_centers (geoid, center)
        VALUES (\$1, \$2)
    """, [row.geoid, row.center])
end

close(conn)

# Create and populate trauma_centers table in tiger.census schema
conn = LibPQ.Connection("dbname=tiger")

# Drop table if it exists
execute(conn, "DROP TABLE IF EXISTS census.trauma_centers")

# Create table
execute(conn, """
    CREATE TABLE census.trauma_centers (
        geoid VARCHAR(5),
        center BOOLEAN
    )
""")

# Insert data
for row in eachrow(trauma_centers)
    execute(conn, """
        INSERT INTO census.trauma_centers (geoid, center)
        VALUES (\$1, \$2)
    """, [row.geoid, row.center])
end
