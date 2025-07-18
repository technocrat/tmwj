include("src/inset_packages.jl")
include("src/constants.jl")
include("src/util.jl")
include("src/inset_data.jl")
include("src/inset_tables.jl")
include("src/inset_colors.jl")
include("src/inset_geo.jl")
include("src/inset_plot.jl")

Legend(f[2, 3],
    [PolyElement(color=trauma_center_color, strokecolor=:black),
     PolyElement(color=nearby_color, strokecolor=:black),
     PolyElement(color=other_color, strokecolor=:black)],
    ["Trauma Centers", "Within 50 Miles", "Other Counties"],
    "County Categories", halign=:right, fontsize=10
)

# Title spanning full width
Label(f[0, :], "US Counties: Level 1 Trauma Centers and Nearby Areas", fontsize = 20)

# Caption below
Label(f[3, 3], "Source: Richard Careaga from https://en.wikipedia.org/wiki/List_of_trauma_centers_in_the_United_States", fontsize = 10, halign=:right)


# Summary table
Label(f[2, 2], table_text; font="DejaVu Sans Mono", fontsize=10, halign=:left, valign=:top)

# Summary text
Label(f[2, 1], squib; fontsize=10, halign=:left, valign=:top, justification=:left)

# North arrow
north_arrow = "\u21E7\nN"
text!(f.scene, north_arrow, 
      position=(0.8, 0.5),
      space=:relative,
      align=(:left, :top), 
      fontsize=36, color=:black)

# Scale bar
map_width = 4.4e6  # approximate width of CONUS in meters
scale_bar_length = (80467.2 / map_width) * 0.8  # 50 miles as fraction of map width
scale_bar_x = 0.85
scale_bar_y = 0.45
lines!(f.scene, [scale_bar_x - scale_bar_length/2, scale_bar_x + scale_bar_length/2], 
       [scale_bar_y, scale_bar_y], 
       space=:relative, color=:black, linewidth=3)

# Scale bar label
text!(f.scene, "50 mi", 
      position=(scale_bar_x, scale_bar_y - 0.02),
      space=:relative,
      align=(:center, :top), 
      fontsize=14, color=:black)

display(f)


