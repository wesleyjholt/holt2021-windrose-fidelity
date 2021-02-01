using PyPlot
using FLOWMath
using DelimitedFiles

function discretize_windrose_single_speed_fromtxt(input_filename, output_filename, ndirs; input_directory="", output_directory="")

    # load original wind resource
    windrose_data = readdlm(input_directory * input_filename, skipstart=1)
    directions_orig = windrose_data[:,1]
    speeds_orig = windrose_data[:,2]
    probs_orig = windrose_data[:,3]

    # create cyclical data
    directions_cyclical = [directions_orig[end-1:end] .- 360.0; directions_orig; directions_orig[1:2] .+ 360.0]
    println(directions_cyclical)
    speeds_cyclical = [reverse(speeds_orig[end-1:end]); speeds_orig; speeds_orig[1:2]]
    probs_cyclical = [reverse(probs_orig[end-1:end]); probs_orig; probs_orig[1:2]]

    # use akima spline to interpolate the pmf to the specified number of wind directions
    directions = range(0, stop=360*(ndirs-1)/ndirs, length=ndirs)
    speeds = akima(directions_cyclical, speeds_cyclical, directions)
    probs = akima(directions_cyclical, probs_cyclical, directions)

    # normalize the interpolated probabilities to make them an actual probability mass function 
    probs /= sum(probs)

    # write out interpolated wind rose file
    open(output_directory * output_filename, "w") do io
        write(io, "# directions, average speeds, frequencies\n")
        writedlm(io, [directions speeds probs])
    end

end

function plot_windrose_single_speed(input_filename, output_filename; input_directory="", output_directory="", show_fig=true, save_fig=false)
    
    # load original wind resource
    windrose_data = readdlm(input_directory * input_filename, skipstart=1)
    directions = windrose_data[:,1]
    speeds = windrose_data[:,2]
    probs = windrose_data[:,3]
    ndirs = length(directions)
    nspeeds = length(speeds)
    directionRes = directions[2] - directions[1]

    # plot windrose
    # create blank figure
    fig = plt.figure(figsize=(8,8))
    # set location of windrose on the figure and change coordinate type to polar
    ax = fig.add_axes(([0.15,0.15,0.75,0.75]), polar=true)
    # set the direction of increasing theta to be clockwise
    ax.set_theta_direction(-1)
    # set theta to start at the vertical axis 
    ax.set_theta_offset(pi/2.0)
    # set color map
    cm = get_cmap(:Blues)
    # plot
    b = plt.bar(directions .* pi/180, probs, width=(directionRes - 3.0/sqrt(ndirs))*pi/180, color=cm(0.5))
    # fig.legend()
    title("Nantucket Wind Rose with " * string(ndirs) * " Directions", fontsize=16)

    if save_fig
        savefig(output_directory * output_filename, dpi=600)
    end

    if show_fig
        plt.show()
    end
end

function create_new_windrose_file_nantucket(ndirs_vec)

    # setup input file
    input_directory = "windrose-files/"
    input_filename = "nantucket-windrose-ave-speeds.txt"

    # setup and create output file(s)
    output_directory = "windrose-files/"
    for ndirs = ndirs_vec
        output_filename = "nantucket-windrose-ave-speeds-" * lpad(ndirs,3,"0") * "dirs.txt"
        discretize_windrose_single_speed_fromtxt(input_filename, output_filename, ndirs; input_directory=input_directory, output_directory=output_directory)
    end

end

function create_new_windrose_plot_nantucket(ndirs_vec)
    
    # set up input and output files, and create the plots
    input_directory = "windrose-files/"
    output_directory = "windrose-files/windrose-figures/"
    for ndirs = ndirs_vec
        input_filename = "nantucket-windrose-ave-speeds-" * lpad(ndirs,3,"0") * "dirs.txt"
        output_filename = "nantucket-windrose-ave-speeds-" * lpad(ndirs,3,"0") * "dirs.png"
        plot_windrose_single_speed(input_filename, output_filename; input_directory=input_directory, output_directory=output_directory, show_fig=true, save_fig=true)
    end

end

# ---- These are the only value that need to be changed. ----
create_new_windrose_file = true
create_new_windrose_plot = true
ndirs_vec = [10 20 30 40 50 60 70 80 90 100 120 150 200 360]
# -----------------------------------------------------------

if create_new_windrose_file
    create_new_windrose_file_nantucket(ndirs_vec)
end

if create_new_windrose_plot
    create_new_windrose_plot_nantucket(ndirs_vec)
end