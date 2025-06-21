using CSV
using DataFrames

# define the states
const states = ["Alabama","Alaska","Arizona","Arkansas","California","Colorado","Connecticut",
"Delaware","District of Columbia","Florida","Georgia","Hawaii","Idaho","Illinois",
"Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts",
"Michigan","Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada",
"New Hampshire","New Jersey","New Mexico","New York","North Carolina","North Dakota",
"Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island","South Carolina","South Dakota",
"Tennessee","Texas","Utah","Vermont","Virginia","Washington","West Virginia","Wisconsin",
"Wyoming"]

"""
    get_gdp(df::DataFrame, quarter::Int) -> DataFrame

Process a GDP dataset to extract state-level GDP data for a specified quarter.

This function cleans and processes a raw GDP DataFrame by:
- Selecting the state names column and the specified quarter column
- Removing header and footer rows that contain explanatory text
- Converting GDP values from strings to integers (removing commas)
- Filtering to include only valid US states
- Sorting the results by state name

# Arguments
- `df::DataFrame`: Raw GDP data with state names in column 1 and quarterly data in subsequent columns
- `quarter::Int`: Column index representing the desired quarter (e.g., 2 for Q1, 3 for Q2, etc.)

# Returns
- `DataFrame`: Cleaned dataset with columns `:state` and `:gdp`, sorted by state name

# Notes
- Assumes data starts at row 6 and state data ends 5 rows before the DataFrame end
- Requires a global variable `states` containing valid state names for filtering
- GDP values are converted to integers after removing comma separators
- First set of quarters are in current dollars, second set are in constant dollars.
- Which to use depends on the context of the analysis.
- This approach is suitable for official data and other series that have very
- consistent formatting from period to period. Otherwise, we would not be able to
- hard code the rows to trim.

# Example
```julia
cleaned_data = get_gdp(raw_gdp_df, 14)  # Extract Q4 data (assuming column 14 contains Q4)
```

"""
function get_gdp(df::DataFrame, quarter::Int)
    # scrubbing
    # by inspection we want columns 1, with the names of states, and the specified column with the latest gdp quarter
    df = df[!, [1, quarter]]
    # the first several rows at the top and bottom are leftover table explanatory matter
    first(df, 10)
    # data does not start until row 6, so trim the first 5 rows
    df = df[6:end, :]
    # state data ends at with line 60, so trim the last 5 rows
    df = df[1:end-5, :]
    # rename the columns to state and gdp
    rename!(df, [:state, :gdp])
    # remove the commas from the gdp column; notice the period after replace
    # this is needed to apply replace to the entire column
    df.gdp = replace.(df.gdp, "," => "")
    # convert the gdp column to an integer
    df.gdp = parse.(Int, df.gdp)
    # some states may have a trailing space in the name, so we need to remove it
    df.state = strip.(df.state)
    # this changes the type of the gdp column to a substring, so we need to convert it back to string
    df.gdp = string.(df.gdp)
    # filter to only include only states
    df = subset(df, :state => ByRow(x -> x in states))
    sort!(df, :state)
    return df
end

export get_gdp