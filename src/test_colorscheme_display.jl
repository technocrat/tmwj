# Test script for colorscheme display function
include("utils.jl")

# Display various colorschemes showing both discrete and continuous versions
println("Displaying colorschemes with both discrete and continuous versions...")

# Viridis (default matplotlib colorscheme)
fig1 = plot_colorscheme(:viridis)
display(fig1)
save("viridis_colorscheme.png", fig1)

# Plasma (another popular colorscheme)
fig2 = plot_colorscheme(:plasma, n_colors=128, figsize=(800, 300))
display(fig2)
save("plasma_colorscheme.png", fig2)

# RdYlBu (red-yellow-blue diverging colorscheme)
fig3 = plot_colorscheme(:RdYlBu)
display(fig3)
save("RdYlBu_colorscheme.png", fig3)

# Coolwarm (another diverging colorscheme)
fig4 = plot_colorscheme(:coolwarm, n_colors=64, figsize=(800, 300))
display(fig4)
save("coolwarm_colorscheme.png", fig4)

# Categorical colorschemes
println("Categorical colorschemes:")

# Paired_9 (categorical colorscheme)
fig5 = plot_colorscheme(:Paired_9)
display(fig5)
save("Paired_9_colorscheme.png", fig5)

# Set1_9 (another categorical colorscheme)
fig6 = plot_colorscheme(:Set1_9, figsize=(800, 300))
display(fig6)
save("Set1_9_colorscheme.png", fig6)

# Accent_8 (another categorical colorscheme)
fig7 = plot_colorscheme(:Accent_8)
display(fig7)
save("Accent_8_colorscheme.png", fig7)

println("All colorschemes displayed and saved!") 