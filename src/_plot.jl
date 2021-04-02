using PyPlot

function plot_initial_final_layout(x_initial, x_final, turbine_design, boundary::CircleBoundary; show_fig=true, save_fig=false, path_to_fig_file="layout.png")

    # add wind farm boundary to plot
    plt.gcf().gca().add_artist(plt.Circle((boundary.center[1],boundary.center[2]), boundary.radius, fill=false, color="black"))
    
    # set figure bounds
    axis("square")
    xlim(boundary.center[1] - boundary.radius*1.3, boundary.center[1] + boundary.radius*1.3)
    ylim(boundary.center[2] - boundary.radius*1.3, boundary.center[1] + boundary.radius*1.3)
    
    # plot turbines
    plot_turbines(x_initial, turbine_design.rotor_diameter, color="C1", alpha=0.1)
    plot_turbines(x_final, turbine_design.rotor_diameter)

    # save figure
    if save_fig
        savefig(path_to_fig_file, dpi=600)
    end

    # show figure
    if show_fig
        plt.show()
    end
end


function plot_initial_final_layout(x_initial, x_final, boundary::RectangleBoundary)

end


function plot_initial_final_layout(x_initial, x_final, boundary::FreeFormBoundary)

end


function plot_multiple_layouts()

end


function plot_turbines(x, rotor_diameter; color="C0", fill=true, alpha=1.0, linestyle="-")

    # get number of turbines
    nturbines = Int(length(x)/2)

    # extract x and y locations of turbines from design variables vector
    turbine_x = x[1:nturbines] 
    turbine_y = x[nturbines+1:end]

    # add initial turbine location to plot
    for i = 1:length(turbine_x)
        plt.gcf().gca().add_artist(plt.Circle((turbine_x[i],turbine_y[i]), rotor_diameter[1]/2.0, fill=fill, color=color, alpha=alpha, linewidth=0.0))
    end

end
