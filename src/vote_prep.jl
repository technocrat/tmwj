# this is a script to read in the educational attainment data and the votes data
# from Census 1501 table and votes fron 2024_votes.csv
# and then join them on the geoid

using CSV
using DataFrames

edfile = "/Users/technocrat/projects/Census.jl/data/ACSST5Y2023.S1501-Data.csv"
educ = CSV.read(edfile, DataFrame)
# there are 771 columns, but we don't need them all
# the/Users/technocrat/projects/Census.jl/data/ACSST5Y2023.S1501-Column-Metadata.csv
# explains the columns
# start with just the first 33
educ = educ[:, 1:33]
# we don't need the margin of error columns; these end in _M

# Drop columns ending in "M" (margin of error columns)
# Drop even-numbered columns (we will be joining on the GEO_ID, so 
# we don't need the :NAME column)
educ = educ[:, 1:2:end]  # Keep only odd-numbered columns
rename!(educ, :GEO_ID => :geoid)

# Alternative: Drop columns ending in "M" (margin of error columns)
# m_columns = filter(name -> endswith(name, "M"), names(educ))
# educ = select(educ, Not(m_columns))
# rename the columns to be the same as the votes data

# the first line is a duplicate header
deleteat!(educ, 1)

# trim the geoid to just the code
educ.geoid = replace.(educ.geoid, "0500000US" => "")


select!(educ, :geoid, :state, :gop_votes, :dem_votes, :S1501_C01_001E, :S1501_C01_002E, :S1501_C01_003E, :S1501_C01_004E, :S1501_C01_005E, :S1501_C01_006E, :S1501_C01_007E, :S1501_C01_008E, :S1501_C01_009E, :S1501_C01_010E, :S1501_C01_011E, :S1501_C01_012E, :S1501_C01_013E)
rename!(educ, :S1501_C01_001E => :pop_18_24, :S1501_C01_002E => :less_than_hs, :S1501_C01_003E => :hs_grad, :S1501_C01_004E => :aa, :S1501_C01_005E => :ba, :S1501_C01_006E => :adult_pop, :S1501_C01_007E => :adult_less_than_hs, :S1501_C01_008E => :adult_hs2, :S1501_C01_009E => :adult_hs3, :S1501_C01_010E => :adult_hs4, :S1501_C01_011E => :adult_aa, :S1501_C01_012E => :adult_ba, :S1501_C01_013E => :adult_grad)
# Convert columns 2-17 to Int64
for col in names(educ)[2:17]
    educ[!, col] = parse.(Int64, educ[!, col])
end
votes = CSV.read("data/2024_votes.csv", DataFrame)
votes.geoid = lpad.(votes.geoid, 5, "0")

df = innerjoin(votes, educ, on=:geoid)
df.margin = df.gop_votes .- df.dem_votes
df.population = df.pop_18_24 .+ df.adult_pop
df.nocollege = df.less_than_hs .+ df.aa .+ df.adult_less_than_hs .+ df.adult_hs2 .+ df.adult_hs3 .+ df.adult_hs4 .+ df.adult_aa
df.college = df.ba .+ df.adult_ba
rename!(df, :adult_grad => :grad)
select!(df, :geoid, :state, :gop_votes, :dem_votes, :margin, :population, :nocollege, :college, :grad)
df.nocollege_pct = df.nocollege ./ df.population
df.college_pct = df.college ./ df.population
df.grad_pct = df.grad ./ df.population
df.margin_pct = df.margin ./ (df.gop_votes .+ df.dem_votes)

select!(df, :geoid, :state, :population, :gop_votes, :dem_votes, :margin_pct,:nocollege_pct, :college_pct, :grad_pct)