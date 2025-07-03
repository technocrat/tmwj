using DataFrames
using GeoDataFrames

# Load the shapefile
gdf = GeoDataFrames.read("data/cb_2018_us_state_500k.shp")

# Show the structure of the data
println("Shapefile columns:")
println(names(gdf))
println("\nFirst few rows of STUSPS column:")
println(first(gdf.STUSPS, 10))

# The problematic acela definition
acela = ["ME,NH,VT,MA,CT,RI,NY,NJ,PA,MD,DE,DC,VA"]
println("\nCurrent acela definition:")
println(acela)
println("Type: ", typeof(acela))
println("Length: ", length(acela))

# This will be empty because acela contains one string with commas
result1 = subset(gdf, :STUSPS => ByRow(x -> x in acela))
println("\nResult with current acela definition:")
println("Number of rows: ", nrow(result1))

# The correct acela definition - split into individual state codes
acela_correct = ["ME", "NH", "VT", "MA", "CT", "RI", "NY", "NJ", "PA", "MD", "DE", "DC", "VA"]
println("\nCorrected acela definition:")
println(acela_correct)
println("Type: ", typeof(acela_correct))
println("Length: ", length(acela_correct))

# This will work correctly
result2 = subset(gdf, :STUSPS => ByRow(x -> x in acela_correct))
println("\nResult with corrected acela definition:")
println("Number of rows: ", nrow(result2))
println("States found: ", result2.STUSPS) 