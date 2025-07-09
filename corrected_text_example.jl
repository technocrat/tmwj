using CairoMakie

# Create a simple figure
fig = Figure()
ax = Axis(fig[1, 1])

# Correct syntax for Makie 0.24.3
text!(ax, 0, 1, text="Hello\nWorld", align=(:left, :top), fontsize=20)

# Alternative syntax using Point2
text!(ax, Point2(0, 0), text="Hello\nWorld", align=(:left, :top), fontsize=20)

# Alternative syntax using vectors
text!(ax, [0], [-1], text="Hello\nWorld", align=(:left, :top), fontsize=20)

display(fig) 