function create_population_bins(population)
    if population < 1e6
        return 1
    elseif population < 8.5e6
        return 2
    elseif population < 12e6
        return 3
    elseif population < 22e6
        return 4
    else
        return 5
    end
end

function create_standard_bins(population)
    if population < 2e6
        return 3
    elseif population < 5e6
        return 2
    elseif population < 10e6
        return 1
    else
        return 4
    end
end