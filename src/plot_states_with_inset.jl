function plot_states_with_inset(conus = conus, alaska_inset = alaska_inset, hawaii_inset = hawaii_inset)
    viz(conus.geometry)
    viz!(alaska_inset.geometry)
    viz!(hawaii_inset.geometry)
    display(current_figure())
end