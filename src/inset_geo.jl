tigerline_file = "data/2024_shp/cb_2024_us_county_500k.shp"
full_geo = GeoDataFrames.read(tigerline_file)
# continental US plots correctly with poly!
conus_geo = innerjoin(full_geo, df, on = :GEOID => :geoid)
conus_geo = subset(conus_geo, :STUSPS => ByRow(x -> x ∈ values(VALID_STATE_CODES)))
conus_geo = subset(conus_geo, :STUSPS => ByRow(x -> x ∉ ["AK", "HI"]))
for area_df in [conus_geo]
    area_df.colores = [area_df.is_trauma_center[i] === true ? trauma_center_color : 
    area_df.nearby[i] === true ? nearby_color : other_color 
    for i in eachindex(area_df.is_trauma_center)]
end
select!(conus_geo, :geometry, :GEOID, :population, :colores)

# Alaska and Hawaii require a different approach

alaska_geo, hawaii_geo = get_counties(tigerline_file)
alaska_df = DataFrame(alaska_geo)
alaska_with_color = innerjoin(alaska_df, df, on = :GEOID => :geoid)
hawaii_df = DataFrame(hawaii_geo)
hawaii_with_color = innerjoin(hawaii_df, df, on = :GEOID => :geoid)
for area_df in [alaska_with_color, hawaii_with_color]
    area_df.color_category = [area_df.is_trauma_center[i] === true ? trauma_center_color : 
    area_df.nearby[i] === true ? nearby_color : other_color 
    for i in eachindex(area_df.is_trauma_center)]
end
alaska_colors = alaska_with_color.color_category
hawaii_colors = hawaii_with_color.color_category

alaska_with_color = GeoTable(alaska_with_color)
hawaii_with_color = GeoTable(hawaii_with_color)

alaska_inset = inset_state(alaska_with_color, 18, 0.25, -2_000_000.0, 420_000, "ccw")
hawaii_inset = inset_state(hawaii_with_color, 24, 0.5, -1_250_000.0, 250_000, "ccw")




