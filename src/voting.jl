using CairoMakie
using CSV
using DataFrames
using GLM
using OLSPlots
using RobustModels
using Statistics
using MLJ, MLJLinearModels
using GLMNet
using GeoDataFrames
using CoordRefSystems
using GeometryBasics
include("src/inset_packages.jl")
include("src/constants.jl")

oh_crs = "+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"


df = CSV.read("data/educ_votes.csv", DataFrame)
df = subset(df, :state => ByRow(x -> x == "Ohio"))
df.geoid = string.(df.geoid)

tigerline_file = "data/2024_shp/cb_2024_us_county_500k.shp"
full_geo = GeoDataFrames.read(tigerline_file)
geo = subset(full_geo, :STUSPS => ByRow(x -> x == "OH"))
geo = select(geo, :geometry, :GEOID)
rename!(geo, :GEOID => :geoid)
df = innerjoin(df, geo, on=:geoid)
select!(df, Not(:state))


function create_bivariate_colorscheme(n_classes=3)
    """
    Create a bivariate color scheme where:
    - X-axis represents margin_pct (bipolar: blue=Dem, red=GOP)
    - Y-axis represents grad_pct (unipolar: light to dark)
    """
    colors = Matrix{RGB{Float64}}(undef, n_classes, n_classes)
    
    # Base colors: Blue for Dem, Red for GOP
    dem_base = colorant"#2166ac"  # Blue
    gop_base = colorant"#b2182b"  # Red
    neutral = colorant"#f7f7f7"   # Light gray for neutral
    
    for i in 1:n_classes
        for j in 1:n_classes
            # i represents margin_pct classes (1=strong Dem, 3=strong GOP)
            # j represents grad_pct classes (1=low education, 3=high education)
            
            if i == 1  # Democratic areas
                base_color = dem_base
            elseif i == 3  # Republican areas
                base_color = gop_base
            else  # Neutral/competitive areas
                base_color = neutral
            end
            
            # Adjust saturation/lightness based on education level
            education_factor = (j - 1) / (n_classes - 1)  # 0 to 1
            
            # Higher education = darker/more saturated
            if i == 2  # Neutral areas
                colors[i, j] = weighted_color_mean(education_factor, colorant"#969696", neutral)
            else
                # Blend with darker version for higher education
                dark_color = weighted_color_mean(0.7, base_color, colorant"#000000")
                colors[i, j] = weighted_color_mean(education_factor, dark_color, base_color)
            end
        end
    end
    
    return colors
end

function classify_bivariate_data(df, margin_col, education_col, n_classes=3)
    """
    Classify data into bivariate classes
    """
    df_copy = copy(df)
    
    # Classify margin_pct (bipolar)
    margin_breaks = quantile(df[!, margin_col], [1/n_classes, 2/n_classes])
    df_copy.margin_class = map(df[!, margin_col]) do x
        if x <= margin_breaks[1]
            1  # Strong Democratic
        elseif x <= margin_breaks[2]
            2  # Competitive
        else
            3  # Strong Republican
        end
    end
    
    # Classify education_col (unipolar)
    education_breaks = quantile(df[!, education_col], [1/n_classes, 2/n_classes])
    df_copy.education_class = map(df[!, education_col]) do x
        if x <= education_breaks[1]
            1  # Low education
        elseif x <= education_breaks[2]
            2  # Medium education
        else
            3  # High education
        end
    end
    
    # Create combined class for color mapping
    df_copy.bivar_class = (df_copy.margin_class .- 1) * n_classes .+ df_copy.education_class
    
    return df_copy, margin_breaks, education_breaks
end

function create_bivariate_map(df::DataFrame, col_name::Symbol)
    """
    Create the bivariate choropleth map
    """
    
    # Define education level labels
    education_labels = Dict(
        :nocollege_pct => "No College",
        :college_pct => "Bachelor's Degree", 
        :grad_pct => "Post Graduate Degree"
    )
    
    education_label = get(education_labels, col_name, string(col_name))
    
    # Classify data
    classified_df, margin_breaks, education_breaks = classify_bivariate_data(
        df, :margin_pct, col_name, 3
    )
    
    # Create color scheme
    colors = create_bivariate_colorscheme(3)
    color_vector = [colors[mod1(i, 3), div(i-1, 3)+1] for i in 1:9]
    
    # Create the map with adjusted layout - map gets more space
    f = Figure(size=(1200, 800))
    # Create a grid layout with specific column widths
    gl = GridLayout(f[1, 1:2])
    gl[1, 1] = GridLayout(width=Relative(0.8))
    gl[1, 2] = GridLayout(width=Relative(0.2))
    ga = GeoAxis(gl[1, 1], aspect=DataAspect(), dest = oh_crs)
    
    # Plot the geometries with bivariate colors
    poly!(ga, classified_df.geometry, 
          color=color_vector[classified_df.bivar_class],
          strokecolor=:white, strokewidth=0.5)
    
    hidedecorations!(ga)
    
    # Create legend in a smaller space
    legend_ax = Axis(gl[1, 2], aspect=1, 
                    title="Political Margin ×\n $education_label",
                    xlabel="Political Lean →", 
                    ylabel="$education_label →",
                    titlesize=12, xlabelsize=10, ylabelsize=10)
    
    # Create legend grid
    for i in 1:3, j in 1:3
        x_pos = i - 0.4
        y_pos = j - 0.4
        poly!(legend_ax, 
              Rect(x_pos, y_pos, 0.8, 0.8),
              color=colors[i, j], strokecolor=:black, strokewidth=0.5)
    end
    
    # Legend labels
    xlims!(legend_ax, 0.5, 3.5)
    ylims!(legend_ax, 0.5, 3.5)
    legend_ax.xticks = (1:3, ["Dem", "Swing", "GOP"])
    legend_ax.yticks = (1:3, ["Low", "Med", "High"])
    legend_ax.xticklabelsize = 9
    legend_ax.yticklabelsize = 9
    
    # Add title
    f[0, :] = Label(f, "Bivariate Map: Ohio 2024 Presidential Election\nPolitical Margin vs $education_label", 
                     fontsize=16, font="bold")
    Label(gl[2, 1:2], "Source: Education compiled from U.S. Census Bureau, 2023 ACS 5-Year Estimates Table S1501, and 2024 Presidential Election Results from https://github.com/tonmcg/US_County_Level_Election_Results_08-24", fontsize = 10, halign=:right)
    return f, classified_df, margin_breaks, education_breaks
end

# Usage example (assuming you have your dataframes ready):
f, classified_data, margin_breaks, education_breaks = create_bivariate_map(df, :nocollege_pct)

# Display the map
display(f)
# 
# # Save the map
# save("bivariate_choropleth.png", fig)

# Print classification breaks for reference
function print_breaks(margin_breaks, grad_breaks)
    println("Classification breaks:")
    println("Margin % breaks: ", round.(margin_breaks, digits=3))
    println("Graduate % breaks: ", round.(grad_breaks, digits=3))
    
    println("\nColor interpretation:")
    println("- Blue areas: Democratic lean")
    println("- Red areas: Republican lean") 
    println("- Gray areas: Competitive")
    println("- Darker colors: Higher graduate education")
    println("- Lighter colors: Lower graduate education")
end