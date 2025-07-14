# Example usage of map utilities from src/utils.jl
include("src/utils.jl")

# Create and display an auto-scaled map
fig = create_auto_scaled_map()
display(fig)

# You can also create other types of maps
fig2 = create_map_with_elements()
display(fig2) 