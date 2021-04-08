abstract type AEPPlot end

struct BoxPlot{} <:AEPPlot
    # box plot for each group of data
end

struct BoxScatterPlot{} <: AEPPlot
    # box plot with overlayed scatter plot for each group of data
end

struct ConfidenceIntervalPlot <: AEPPlot
    # confidence interval plot
end

struct ConfidenceIntervalScatterPlot <: AEPPlot
    # confidence interval with scatter plot
end


include("_boundary.jl")
using PyPlot
using DelimitedFiles
using FillArrays
using Statistics

"""
    plot_initial_final_layout(x_initial, x_final, turbine_design, boundary::CircleBoundary; show_fig=true, save_fig=false, path_to_fig_file="layout.png")

Plots the initial and final layouts of circular wind farm.

# Arguments
- `x_initial::Array{Float64,1}`: initial turbine x and y coordinates, all concatenated into a single column vector
- `x_final::Array{Float64,1}`: final turbine x and y coordinates, all concatenated into a single column vector
- `turbine_design::TurbineType`: container holding all design parameters for a turbine type
- `boundary::CircleBoundary`: container holding parameters for a circular wind farm boundary
"""
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


function plot_initial_final_layout(x_initial, x_final, turbine_design, boundary::RectangleBoundary; show_fig=true, save_fig=false, path_to_fig_file="layout.png")

end


function plot_initial_final_layout(x_initial, x_final, turbine_design, boundary::FreeFormBoundary; show_fig=true, save_fig=false, path_to_fig_file="layout.png")

    # add wind farm boundary to plot
    boundary_vertices_closed = [boundary.vertices; reshape(boundary.vertices[1,:], 1, 2)]
    plt.gcf().gca().plot(boundary_vertices_closed[:,1], boundary_vertices_closed[:,2], color="black")
    
    # set figure bounds
    axis("square")
    xmin = minimum(boundary.vertices[:,1])
    xmax = maximum(boundary.vertices[:,1])
    ymin = minimum(boundary.vertices[:,2])
    ymax = maximum(boundary.vertices[:,2])
    xrange = xmax - xmin
    yrange = ymax - ymin
    plot_window_buffer = 0.1
    xlim(xmin - xrange*plot_window_buffer, xmax + xrange*plot_window_buffer)
    ylim(ymin - yrange*plot_window_buffer, ymax + yrange*plot_window_buffer)
    
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


function plot_overlayed_layouts()

end

"""
    plot_turbines(x, rotor_diameter; color="C0", fill=true, alpha=1.0, linestyle="-")

Plots turbines

# Arguments
- `x::Array{Float64,1}`: turbine x and y coordinates, all concatenated into a single column vector
- `rotor_diameter::Float64`: rotor diamter of the turbines
"""
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



"""
    plot_aeps(data_file_names, labels, plot_type::BoxPlot; show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts")
"""
function plot_aeps(data_file_names, x_values, plot_type::BoxPlot; fig_handle="", ax_handle="", show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts")

    # get figure and axes handles
    fig, ax = get_fig_ax_handles(fig_handle, ax_handle)
    # get the AEP values from the files
    aeps = get_aep_values_from_file_names(data_file_names)
    # create box plots
    create_box_plots(x_values, aeps, ax)
    # add plot labels
    add_aep_plot_labels(title, aeps)
    # save figure
    if save_fig
        mkpath(path_to_fig_directory)
        savefig(path_to_fig_directory * fig_file_name , dpi=600)
    end
    # show figure
    if show_fig
        plt.show()
    end
end



"""
    plot_aeps(data_file_names, labels, plot_type::BoxScatterPlot; show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts")
"""
function plot_aeps(data_file_names, x_values, plot_type::BoxScatterPlot; fig_handle="", ax_handle="", show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts")

    # get figure and axes handles
    fig, ax = get_fig_ax_handles(fig_handle, ax_handle)
    # get the AEP values from the files
    aeps = get_aep_values_from_file_names(data_file_names)
    # create box plots
    create_box_plots(x_values, aeps, ax)
    # create scatter plots
    create_aep_scatter_plots(1:length(aeps), aeps, size=2)
    # add plot labels
    add_aep_plot_labels(title, aeps)
    # save figure
    if save_fig
        mkpath(path_to_fig_directory)
        savefig(path_to_fig_directory * fig_file_name, dpi=600)
    end
    # show figure
    if show_fig
        plt.show()
    end
end



"""
    plot_aeps(data_file_names, labels, plot_type::ConfidenceIntervalPlot; show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts")
"""
function plot_aeps(data_file_names, x_values, plot_type::ConfidenceIntervalPlot; fig_handle="", ax_handle="", show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts")

    # get figure and axes handles
    fig, ax = get_fig_ax_handles(fig_handle, ax_handle)
    # get the AEP values from the files
    aeps = get_aep_values_from_file_names(data_file_names)
    # create mean line with confidence interval
    create_confidence_interval_plot(x_values, aeps)
    # add plot labels
    add_aep_plot_labels(title, aeps)
    # save figure
    if save_fig
        mkpath(path_to_fig_directory)
        savefig(path_to_fig_directory * fig_file_name , dpi=600)
    end
    # show figure
    if show_fig
        plt.show()
    end
end


"""
    plot_aeps(data_file_names, labels, plot_type::ConfidenceIntervalScatterPlot; show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts")
"""
function plot_aeps(data_file_names, x_values, plot_type::ConfidenceIntervalScatterPlot; fig_handle="", ax_handle="", show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts")

    # get figure and axes handles
    fig, ax = get_fig_ax_handles(fig_handle, ax_handle)
    # get the AEP values from the files
    aeps = get_aep_values_from_file_names(data_file_names)
    # create scatter plots
    create_aep_scatter_plots(x_values, aeps)
    # create mean line with confidence interval
    create_confidence_interval_plot(x_values, aeps)
    # add plot labels
    add_aep_plot_labels(title, aeps)
    # save figure
    if save_fig
        mkpath(path_to_fig_directory)
        savefig(path_to_fig_directory * fig_file_name , dpi=600)
    end
    # show figure
    if show_fig
        plt.show()
    end
end


function get_aep_values_from_file_names(data_file_names)
    # get the AEP values from the files
    ngroups = length(data_file_names)
    aeps = fill(zeros(1), ngroups)
    for i = 1:ngroups
        aeps[i] = readdlm(data_file_names[i], skipstart=1)[:,1]
    end
    return aeps
end

function create_box_plots(x_values, aeps, ax)
    flierprops = Dict{String, Any}()
    flierprops["markersize"] = 3
    flierprops["markeredgewidth"] = 0.5
    plt.boxplot(aeps, whis=(5, 95), flierprops=flierprops, zorder=1)
    ax.set_xticklabels(round.(x_values, digits=1))
    ax.xaxis.grid(true, alpha=0.2, linestyle="--")
end



function create_aep_scatter_plots(x_values, aeps; alpha=0.3, size=2, jitter_standard_dev=0.05)
    for i = 1:length(aeps)
        x = zeros(length(aeps[i])) .+ x_values[i] .+ randn(length(aeps[i]))*jitter_standard_dev
        plt.scatter(x, aeps[i], color="C0", alpha=alpha, s=size, zorder=10)
    end
end

function create_confidence_interval_plot(x_values, aeps, confidence_interval_width=1.0)
    aeps_means = mean.(aeps)
    aeps_sd = std.(aeps)
    aeps_lower_CI = aeps_means - aeps_sd*confidence_interval_width
    aeps_upper_CI = aeps_means + aeps_sd*confidence_interval_width
    plt.plot(x_values, aeps_means, color="black", alpha=0.5, linewidth=1)
    plt.fill_between(x_values, aeps_lower_CI, aeps_upper_CI, color="black", alpha=0.1, linewidth=0.0)
end

function add_aep_plot_labels(title, aeps; xlabel=L"\Delta\theta")
    plt.title("$title\n($(length(aeps[1])) random layouts for each wind rose)")
    plt.xlabel(L"\Delta\theta")
    plt.ylabel("AEP (MWh)")
end


function get_fig_ax_handles(fig_handle, ax_handle)

    if fig_handle==""
        fig = plt.figure()
    else
        fig = fig_handle
    end
    
    if ax_handle==""
        ax = fig.add_axes([0.15, 0.1, 0.8, 0.8])
    else
        ax = ax_handle
    end

    return fig, ax
end

