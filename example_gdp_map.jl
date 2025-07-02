using DataFrames
using CSV
using CairoMakie
using ColorSchemes

# Load the data
println("Loading data...")
pop_df = CSV.read("data/pop_death_money.csv", DataFrame)
gdp_df = CSV.read("data/gdp.csv", DataFrame)

# Clean state names
pop_df.State = strip.(pop_df.State)
gdp_df.State = strip.(gdp_df.State)

# Merge the data
df = leftjoin(pop_df, gdp_df, on=:State)

println("Data loaded successfully!")
println("Number of states: ", nrow(df))
println("GDP range: ", minimum(df.GDP), " to ", maximum(df.GDP))

# Create GDP bins using quantiles
gdp_values = filter(!isnan, df.GDP)
breaks = quantile(gdp_values, [0, 0.2, 0.4, 0.6, 0.8, 1.0])
breaks = unique(breaks)

println("GDP breaks: ", breaks)

# Assign bins to each state
df.bin = zeros(Int, nrow(df))
for (i, gdp) in enumerate(df.GDP)
    if isnan(gdp)
        df.bin[i] = 0  # Missing data
    else
        for (j, break_point) in enumerate(breaks)
            if gdp <= break_point
                df.bin[i] = j
                break
            end
        end
        if df.bin[i] == 0
            df.bin[i] = length(breaks)  # Above all breaks
        end
    end
end

# Format GDP labels for display
function format_gdp_label(gdp_value)
    if gdp_value >= 1e12
        return @sprintf("%.1fT", gdp_value / 1e12)
    elseif gdp_value >= 1e9
        return @sprintf("%.1fB", gdp_value / 1e9)
    else
        return @sprintf("%.0fM", gdp_value / 1e6)
    end
end

# Create a simple bar chart showing GDP by state
println("Creating GDP visualization...")

fig = Figure(resolution=(1400, 800))
ax = Axis(fig[1, 1], 
          title="US States GDP (2023)",
          xlabel="State",
          ylabel="GDP (USD)",
          xticklabelrotation=45)

# Sort by GDP for better visualization
sorted_df = sort(df, :GDP, rev=true)

# Create bars with colors based on bins
colors = ColorSchemes.viridis
for (i, row) in enumerate(eachrow(sorted_df))
    if row.bin > 0
        barplot!(ax, [i], [row.GDP], color=colors[row.bin])
    else
        barplot!(ax, [i], [row.GDP], color=:lightgray)
    end
end

# Set x-axis labels
ax.xticks = (1:nrow(sorted_df), sorted_df.State)

# Add colorbar
valid_bins = unique(filter(x -> x > 0, sorted_df.bin))
if !isempty(valid_bins)
    dummy_data = reshape(valid_bins, length(valid_bins), 1)
    hm = heatmap!(ax, dummy_data, colormap=colors, visible=false)
    Colorbar(fig[1, 2], hm, 
            label="GDP Bins", 
            ticks=valid_bins,
            ticklabels=[format_gdp_label(breaks[i]) for i in valid_bins])
end

# Add legend for missing data
if any(sorted_df.bin .== 0)
    Legend(fig[1, 3], 
          [PolyElement(color=:lightgray)],
          ["No Data"],
          "Missing Data")
end

display(fig)

# Print summary statistics
println("\nGDP Summary Statistics:")
println("Total GDP: ", format_gdp_label(sum(filter(!isnan, df.GDP))))
println("Average GDP: ", format_gdp_label(mean(filter(!isnan, df.GDP))))
println("Median GDP: ", format_gdp_label(median(filter(!isnan, df.GDP))))

# Show top 5 states by GDP
println("\nTop 5 States by GDP:")
top_5 = first(sort(df, :GDP, rev=true), 5)
for (i, row) in enumerate(eachrow(top_5))
    println("$i. $(row.State): $(format_gdp_label(row.GDP))")
end

# Show bottom 5 states by GDP
println("\nBottom 5 States by GDP:")
bottom_5 = first(sort(df, :GDP), 5)
for (i, row) in enumerate(eachrow(bottom_5))
    println("$i. $(row.State): $(format_gdp_label(row.GDP))")
end

println("\nVisualization complete!")