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

struct SurfacePlot <: AEPPlot
    # surface plot (using Plots.jl package)
end


include("_boundary.jl")
using PyPlot
# import Plots
# using Plots.PlotMeasures
using DelimitedFiles
using FillArrays
using Statistics
using GridInterpolations

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


function plot_aeps(data_file_names::Array{String,2}, x_values, y_values, plot_type::SurfacePlot; fig_handle="", ax_handle="", show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts", xlabel="", ylabel="")

    Plots.gr()
    # get the AEP values from the files
    aeps = get_aep_values_from_file_names(data_file_names)
    # specify the number of groups
    n_x = length(x_values)
    n_y = length(y_values)
    # get x and y arrays
    X = x_values .* ones(n_x)
    Y = ones(n_y) .* y_values
    # get mean AEP value for each X-Y combination
    mean_aeps = zeros(n_ndirs_vec, n_nspeeds_vec)
    for i = 1:n_ndirs_vec
        for j = 1:n_nspeeds_vec
            mean_aeps[i,j] = mean(aeps[i,j])
        end
    end
    # normalize the mean AEP values
    norm_mean_aeps = mean_aeps ./ maximum(mean_aeps) * 100.0
    println(norm_mean_aeps)
    # reverse n_directions vector to be in ascending order
    x_values_reversed = reverse(x_values)
    norm_mean_aeps_reversed = reverse(norm_mean_aeps, dims=1)
    # interpolate mean AEP values onto a finer grid for plotting
    x_plot = range(minimum(x_values), stop=maximum(x_values), length=100)
    y_plot = range(minimum(y_values), stop=maximum(y_values), length=100)
    grid = RectangleGrid(x_values_reversed, y_values)
    z_plot = zeros(length(x_plot), length(y_plot))
    for i = 1:length(x_plot)
        for j = 1:length(y_plot)
            z_plot[i,j] = interpolate(grid, norm_mean_aeps_reversed, [x_plot[i], y_plot[j]])
        end
    end

    # # create heatmap
    # Plots.plot(x_plot, y_plot, z_plot, 
    #     st=:heatmap, 
    #     c=:blues, 
    #     background_color=:white, 
    #     foreground_color=:black, 
    #     top_margin = 10px,
    #     xlabel=xlabel,
    #     ylabel=ylabel,
    #     colorbar_title = "Normalized AEP (%)",
    #     framestyle=:box,
    #     clims=(minimum(norm_mean_aeps), maximum(norm_mean_aeps)),
    #     dpi=500
    #     )
    
    # create contour plot
    Plots.plot(x_plot, y_plot, z_plot, 
        st=:contour, 
        fill=true,
        c=:blues, 
        background_color=:white, 
        foreground_color=:black, 
        foreground_color_border=:black,
        top_margin=10px,
        right_margin=20px,
        left_margin=10px,
        bottom_margin=20px,
        linewidth=0,
        xlabel=xlabel,
        ylabel=ylabel,
        colorbar_title = "Normalized AEP (%)",
        framestyle=:box,
        clims=(minimum(norm_mean_aeps), maximum(norm_mean_aeps)),
        dpi=500
        )
    
    # save figure
    if save_fig
        mkpath(path_to_fig_directory)
        Plots.savefig(path_to_fig_directory * fig_file_name)
    end
    # show figure
    if show_fig
        plt.show()
    end
end


"""
    plot_aeps(data_file_names, labels, plot_type::BoxPlot; show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts")
"""
function plot_aeps(data_file_names::Array{String,1}, x_values, plot_type::BoxPlot; fig_handle="", ax_handle="", show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots.png", title="AEP Values for Optimized Layouts", xlabel="")

    # get figure and axes handles
    fig, ax = get_fig_ax_handles(fig_handle, ax_handle)
    # get the AEP values from the files
    aeps = get_aep_values_from_file_names(data_file_names)
    # create box plots
    create_box_plots(x_values, aeps, ax)
    # add plot labels
    add_aep_plot_labels(type=plot_type, title=title, xlabel=xlabel)
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
function plot_aeps(data_file_names::Array{String,1}, x_values, plot_type::BoxScatterPlot; fig_handle="", ax_handle="", show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_boxplots_with_scatter.png", title="AEP Values for Optimized Layouts", xlabel="")

    # get figure and axes handles
    fig, ax = get_fig_ax_handles(fig_handle, ax_handle)
    # get the AEP values from the files
    aeps = get_aep_values_from_file_names(data_file_names)
    # create box plots
    create_box_plots(x_values, aeps, ax)
    # create scatter plots
    create_aep_scatter_plots(1:length(aeps), aeps, size=2)
    # add plot labels
    add_aep_plot_labels(type=plot_type, title=title, xlabel=xlabel)
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
function plot_aeps(data_file_names::Array{String,1}, x_values, plot_type::ConfidenceIntervalPlot; fig_handle="", ax_handle="", show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_confidence_interval_plot.png", title="AEP Values for Optimized Layouts", xlabel="")

    # get figure and axes handles
    fig, ax = get_fig_ax_handles(fig_handle, ax_handle)
    # get the AEP values from the files
    aeps = get_aep_values_from_file_names(data_file_names)
    # create mean line with confidence interval
    create_confidence_interval_plot(x_values, aeps)
    # add plot labels
    add_aep_plot_labels(type=plot_type, title=title, xlabel=xlabel)
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
function plot_aeps(data_file_names::Array{String,1}, x_values, plot_type::ConfidenceIntervalScatterPlot; fig_handle="", ax_handle="", show_fig=false, save_fig=true, path_to_fig_directory="", fig_file_name="aep_confidence_interval_plot_with_scatter.png", title="AEP Values for Optimized Layouts", xlabel="")

    # get figure and axes handles
    fig, ax = get_fig_ax_handles(fig_handle, ax_handle)
    # get the AEP values from the files
    aeps = get_aep_values_from_file_names(data_file_names)
    # create scatter plots
    create_aep_scatter_plots(x_values, aeps)
    # create mean line with confidence interval
    create_confidence_interval_plot(x_values, aeps)
    # add plot labels
    add_aep_plot_labels(type=plot_type, title=title, xlabel=xlabel)
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


function get_aep_values_from_file_names(data_file_names::Array{String,1})
    # get the AEP values from the files
    ngroups = length(data_file_names)
    aeps = fill(zeros(1), ngroups)
    for i = 1:ngroups
        aeps[i] = readdlm(data_file_names[i], skipstart=1)[:,1]
    end
    return aeps
end


function get_aep_values_from_file_names(data_file_names::Array{String,2})
    # specify the number of groups
    n_ndirs_vec = length(data_file_names[:,1])
    n_nspeeds_vec = length(data_file_names[1,:])
    # get AEP values from files
    aeps = fill(zeros(1), n_ndirs_vec, n_nspeeds_vec)
    for i = 1:n_ndirs_vec
        for j = 1:n_nspeeds_vec
            aeps[i,j] = readdlm(data_file_names[i,j], skipstart=1)[:,1]
        end
    end
    return aeps
end


function create_aep_surface(x_values, y_values, aeps)

    # specify the number of groups
    n_x = length(x_values)
    n_y = length(y_values)
    # get x and y arrays
    X = x_values .* ones(n_x)
    Y = ones(n_y) .* y_values
    # get mean AEP value for each X-Y combination
    mean_aeps = zeros(n_ndirs_vec, n_nspeeds_vec)
    for i = 1:n_ndirs_vec
        for j = 1:n_nspeeds_vec
            mean_aeps[i,j] = mean(aeps[i,j])
        end
    end
    # create surface plot
    Plots.plot(x_values, y_values, mean_aeps, st=:surface, c=:blues, camera=(90,90), zaxis=false)
    # ax = plt.gca()
    # ax.view_init(90, 90)
    # ax.w_zaxis.line.set_lw(0.)
    # ax.set_zticks([])
    # plt.colorbar(colormap)
    # plt.gcf().colorbar(surf, shrink=0.5, aspect=5)
end


function create_box_plots(x_values, aeps, ax)
    flierprops = Dict{String, Any}()
    flierprops["markersize"] = 3
    flierprops["markeredgewidth"] = 0.5
    plt.boxplot(aeps, whis=(5, 95), flierprops=flierprops, zorder=1)
    if isa(x_values, Array{Float64,1})
        ax.set_xticklabels(round.(x_values, digits=1))
    else
        ax.set_xticklabels(x_values)
    end
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

function add_aep_plot_labels(; type=type::Union{BoxPlot, BoxScatterPlot, ConfidenceIntervalPlot, ConfidenceIntervalScatterPlot}, title="", xlabel="", ylabel="AEP (MWh)")
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
end

function add_aep_plot_labels(; type=type::SurfacePlot, title="", xlabel="", ylabel="")
    Plots.plot(title=title)
    # Plots.xlabel(xlabel)
    # Plots.ylabel(ylabel)
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

