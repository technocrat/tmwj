# Calculate statistics using full data
total_counties = size(df, 1)
trauma_counties = sum(skipmissing(df.is_trauma_center))
nearby_counties = sum(skipmissing(df.nearby))
other_counties = total_counties - trauma_counties - nearby_counties

# Format statistics for display
total_counties_fmt = lpad(with_commas(total_counties), 12)
trauma_counties_fmt = lpad(with_commas(trauma_counties), 12)
nearby_counties_fmt = lpad(with_commas(nearby_counties), 12)
other_counties_fmt = lpad(with_commas(other_counties), 12)

served = subset(df, [:is_trauma_center, :nearby] => ByRow((tc, nb) -> (tc === true) || (nb === true)))
percentage_counties_served = percent(nrow(served) / nrow(df))
percentage_served_population = percent(Float64(sum(skipmissing(served.population)) / sum(skipmissing(df.population))))
total_population = with_commas(sum(skipmissing(df.population)))
served_population = with_commas(sum(skipmissing(served.population)))
all_counties = with_commas(nrow(df))
served_counties = with_commas(nrow(served))

# Create table
headers = ["Category", "Counties"]
rows = [["Trauma Center", trauma_counties_fmt], ["Nearby", nearby_counties_fmt], ["Other", other_counties_fmt], ["Total", total_counties_fmt]]
table_text = format_table_as_text(headers, rows)

# Create descriptive text
squib = "Of the $all_counties counties in the continental United States, $served_counties have a Level 1 trauma center within 50 miles, or $percentage_counties_served of the counties. This represents $served_population of the total population, or $percentage_served_population. Alaska has no Level 1 trauma centers and relies on air ambulance services to transport patients to Level 1 trauma centers in the lower 48 states. Hawaii has one Level 1 trauma center, in Honolulu, and relies on air ambulance services to transport patients from other islands."
squib = hard_wrap(squib, 60)