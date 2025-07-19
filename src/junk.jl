using Plots
import PyPlot
plt = PyPlot

ENV["GKSwstype"] = "100"  # forces GR to use a GUI window
gr()  # explicitly set backend

function test()
    x = 1:10
    y = rand(10)

    p = plot(x, y, label="Random Data", title="Sample Plot")
    display(p)  # Still not always reliable with GR in script mode

    p2 = plot(x.^2, sqrt.(y), label="More Random Data", title="Another Sample Plot", reuse=false)
    display(p2)

    gui()  # <- This is the key: forces the plot windows to open (GR-specific)

    return p, p2
end


function test_plt()
    x = 1:10
    y = rand(10)

    plt.figure()
    plt.plot(x, y, label="Random Data")
    plt.title("Sample Plot with PyPlot")
    plt.legend()

    plt.figure()
    plt.plot(x.^2, sqrt.(y), label="More Random Data")
    plt.title("Another Sample Plot with PyPlot")
    plt.legend()

    nothing
end



function test2()
    x = 1:10
    y = rand(10)

    p = plot(title="Sample Plot, does not appear")
    plot!(p, x, y, label="Random Data")
    # Very weird that this does nothing!

    p2 = plot(title="Another Sample Plot", reuse=false)
    plot!(p2, x.^2, sqrt.(y), label="More Random Data")
    return p, p2
    
end

function test_plt()
    x = 1:10
    y = rand(10)

    plt.figure()
    plt.plot(x, y, label="Random Data")
    plt.title("Sample Plot with PyPlot")
    plt.legend()

    plt.figure()
    plt.plot(x.^2, sqrt.(y), label="More Random Data")
    plt.title("Another Sample Plot with PyPlot")
    plt.legend()

    nothing
end

test()
test_plt()