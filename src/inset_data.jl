# Load trauma center data
df = CSV.read("data/trauma_centers.csv", DataFrame)
df.geoid = lpad.(df.geoid, 5, "0")
df.statefp = lpad.(df.statefp, 2, "0")
select!(df, :geoid, :population, :is_trauma_center, :nearby, :statefp)

# Clean up nearby data
df.nearby[df.is_trauma_center] .= false




