

# # Fixed sizes (absolute units)
# colsize!(f.layout, 1, Fixed(600))  # Map: 600 units wide
# colsize!(f.layout, 2, Fixed(80))   # Colorbar: 80 units wide

# # Relative sizes (fractions of available space)
# colsize!(f.layout, 1, Relative(0.8))  # Map: 80% of width
# colsize!(f.layout, 2, Relative(0.2))  # Colorbar: 20% of width

# Auto sizing with weights
# colsize!(f.layout, 1, Auto(3))  # Map gets 3x more space
# colsize!(f.layout, 2, Auto(1))  # Colorbar gets 1x space


# save("plot_4.pdf", f)