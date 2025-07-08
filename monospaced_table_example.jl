using CairoMakie
using PrettyTables

# Prepare your data and header
header = ["Total Counties", "Trauma Centers", "Nearby Counties", "Other Counties"]
data = ["3,126" "157" "1,126" "1,843"]

# Capture PrettyTables output as a string
io = IOBuffer()
pretty_table(io, data, header=header)
table_str = String(take!(io))

# Create a figure and add the table as a label with a monospaced font
fig = Figure(size=(800, 400))
Label(fig[1, 1], table_str; font="DejaVu Sans Mono", fontsize=24, halign=:left, valign=:top)
fig[0, 1] = Label(fig, "Trauma Center Statistics", fontsize=32)

display(fig) 