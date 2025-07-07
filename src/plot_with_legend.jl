using CairoMakie
using ColorSchemes
using GeoMakie
include("src/plot_base_map.jl")
include("src/constants.jl")

function plot_with_legend(df)
       fig, trauma_center_color, nearby_color, other_color = plot_base_map(df)

       Legend(fig[1, 2], 
              [PolyElement(color=trauma_center_color, strokecolor=:black),
              PolyElement(color=nearby_color, strokecolor=:black),
              PolyElement(color=other_color, strokecolor=:black)],
              ["Trauma Centers", "Within 50 Miles", "Other Counties"],
              "County Categories")
       return fig
end