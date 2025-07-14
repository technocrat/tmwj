using Pkg; Pkg.activate(@__DIR__)
include("src/inset_packages.jl")
include("src/constants.jl")
include("src/plot_states_with_inset.jl")
include("src/get_states.jl")
include("src/rotation_table.jl")
include("src/inset_functions.jl")

tigerline_file = "data/2024_shp/cb_2024_us_state_500k.shp"
conus, alaska, hawaii = get_inset_states(tigerline_file)

show_rotation_table()

# The inset function takes the following arguments:
# 1. The state to inset: alaska or hawaii (unquoted)
# 2. The rotation angle: see rotation table
# 3. The scale factor: controls the size of the inset for the state
# 4. The x-offset: controls east-west position (negative = west, positive = east)
# 5. The y-offset: controls north-south position (negative = south, positive = north)
# 6. The direction: "cw" (clockwise) counterclockwise is the default

alaska_inset = inset_state(alaska, 18, 0.25, -2_000_000, 420_000, "ccw")
hawaii_inset = inset_state(hawaii, 24, 0.5, -1_250_000, 250_000, "ccw")

# Note: the main plot appears compressed but the relative 
# positions of the insets are correct
plot_states_with_inset(conus, alaska_inset, hawaii_inset)








