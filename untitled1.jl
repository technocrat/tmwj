using Pkg; Pkg.activate()
using CairoMakie
using CSV
using DataFrames
using GeoDataFrames
using GeoMakie
using HTTP
url = "https://raw.githubusercontent.com/technocrat/tmwj/refs/heads/main/data/deaths.csv"
resp = HTTP.get(url)
buf  = IOBuffer(resp.body)
df = CSV.read(buf, DataFrame)
df = CSV.read("data/pop_death_money.csv", DataFrame)
gdf = GeoDataFrames.read("data/cb_2018_us_state_500k.shp")
df = innerjoin(df, gdf, on = :State => :NAME)
select!(df, :State, :Deaths, :Population, :Expend, :geometry)
deport = CSV.read("data/deportees.csv", DataFrame)
dropmissing!(deport)
deport.State = titlecase.(deport.State)
male = subset(deport, :Gender => ByRow(x -> x == "Male"))
female = subset(deport, :Gender => ByRow(x -> x == "Female"))

# Count records by state for males
male_sum = combine(groupby(male, :State), nrow => :Male)

# Count records by state for females  
female_sum = combine(groupby(female, :State), nrow => :Female)

df = innerjoin(df, male_sum, on = :State)
df = innerjoin(df, female_sum, on = :State)
select!(df, :State, :Deaths, :Population, :Expend, :geometry, :Male, :Female)

ak_hi = ["Alaska", "Hawaii"]
conus = subset(df, :State => ByRow(x -> x ∉ ak_hi))


fig = Figure(size = (1600,800), fontsize = 24)
ga = GeoAxis(fig[1, 1];
dest = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5
+lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
xgridvisible       = false, ygridvisible = false,
xticksvisible      = false, yticksvisible = false,
xticklabelsvisible = false, yticklabelsvisible = false) 
poly!(ga, conus.geometry, colormap = :PuBu)
display(fig)

quick_hist(conus.Deaths,"","","")
quick_hist(conus.Population,"","","")
quick_hist(conus.Expend,"","","")
quick_hist(conus.Male,"","","")
quick_hist(conus.Female,"","","")

# Create figure with CairoMakie backend
fig = Figure(size = (3200,1600), fontsize = 48)
titled = "Deaths by State"
# Create the GeoAxis
ga = GeoAxis(fig[1, 1];
    dest               = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
    title              = titled,
    aspect             = DataAspect(),
    xgridvisible       = false, ygridvisible = false,
    xticksvisible      = false, yticksvisible = false,
    xticklabelsvisible = false, yticklabelsvisible = false
)  
poly!(ga, conus.geometry, conus.Male, colormap = :Blues9)
display(fig)   

# Plot conus.Deaths as a continuous field
fig2 = Figure(size = (3200,1600), fontsize = 48)
titled2 = "Deaths by State (Continuous)"
ga2 = GeoAxis(fig2[1, 1];
    dest               = "+proj=aea +lat_0=37.5 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs",
    title              = titled2,
    aspect             = DataAspect(),
    xgridvisible       = false, ygridvisible = false,
    xticksvisible      = false, yticksvisible = false,
    xticklabelsvisible = false, yticklabelsvisible = false
)
poly!(ga2, conus.geometry, color=conus.Deaths, colormap=:Reds, strokecolor=:black, strokewidth=0.5)
Colorbar(fig2[1, 2], label="Deaths", colormap=:Reds)
display(fig2)   
