tigerline_file = "data/2024_shp/cb_2024_us_county_500k.shp"
full_geo = GeoDataFrames.read(tigerline_file)
# continental US plots correctly with poly!
conus_geo = subset(full_geo, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
conus_geo = subset(conus_geo, :STUSPS => ByRow(x -> x ∉ ["AK", "HI"]))
alaska_geo = subset(full_geo, :STUSPS => ByRow(x -> x == "AK"))
hawaii_geo = subset(full_geo, :STUSPS => ByRow(x -> x == "HI"))
conus = innerjoin(conus_geo, df, on = :GEOID => :geoid) 
alaska = innerjoin(alaska_geo, df, on = :GEOID => :geoid)
hawaii = innerjoin(hawaii_geo, df, on = :GEOID => :geoid)
for area_df in [conus, alaska, hawaii]
    area_df.colores = [area_df.is_trauma_center[i] === true ? trauma_center_color : 
    area_df.nearby[i] === true ? nearby_color : other_color 
    for i in eachindex(area_df.is_trauma_center)]
end


select!(conus, :geometry, :GEOID, :population, :colores)
select!(alaska, :geometry, :GEOID, :population, :colores)
select!(hawaii, :geometry, :GEOID, :population, :colores)

conus_meters = transform_to_meters(conus.geometry)
# Position Alaska in the lower left with more space, larger scale
alaska.geometry = transform_alaska_to_latlon_fixed(alaska.geometry, 0.6, -125.0, 25.0)
# Make Hawaii bigger and position it better in the Pacific
hawaii.geometry = transform_hawaii_to_latlon(hawaii.geometry, 0.8, -125.0, 22.0)






