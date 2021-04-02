using PyPlot
using FLOWMath
using DelimitedFiles
using Distributions
using FillArrays
using Trapz
import YAML

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

function resample_discretized_windrose_multiple_speeds_weibull(directions_orig, direction_probabilities_orig, speed_weibull_params_orig, ndirs, nspeeds)

    # create cyclical data
    directions_orig_cyclical = [directions_orig[end-1:end] .- 360.0; directions_orig; directions_orig[1:2] .+ 360.0]
    direction_probabilities_orig_cyclical = [direction_probabilities_orig[end-1:end]; direction_probabilities_orig; direction_probabilities_orig[1:2]]
    speed_weibull_params_orig_cyclical = [speed_weibull_params_orig[end-1:end,:]; speed_weibull_params_orig; speed_weibull_params_orig[1:2,:]]

    # get direction and speed vectors
    directions = range(0, stop=360*(ndirs-1)/ndirs, length=ndirs)
    delta_speed = 25.0/nspeeds
    speeds = range(0.0 + delta_speed/2, stop = 25.0 - delta_speed/2, step = delta_speed)
    speed_bin_edges = range(0.0, stop=25.0, length=nspeeds+1)

    # use akima spline to interpolate the probabilities and weibull parameters to the specified number of wind directions
    direction_probabilities = akima(directions_orig_cyclical, direction_probabilities_orig_cyclical, directions)
    speed_weibull_params = zeros(ndirs, 2)
    speed_weibull_params[:,1] = akima(directions_orig_cyclical, speed_weibull_params_orig_cyclical[:,1], directions)
    speed_weibull_params[:,2] = akima(directions_orig_cyclical, speed_weibull_params_orig_cyclical[:,2], directions)

    # normalize the interpolated probabilities to make them an actual probability mass function 
    direction_probabilities /= sum(direction_probabilities)

    # get the speed probabilities for each direction
    speed_probabilities = fill(zeros(length(speeds)), ndirs)
    for i = 1:ndirs
        dist = Weibull(speed_weibull_params[i,:]...)
        speed_probabilities[i] = cdf.(dist, speed_bin_edges[2:end]) - cdf.(dist, speed_bin_edges[1:end-1])
        # normalize
        speed_probabilities[i] ./= sum(speed_probabilities[i])
    end

    return directions, direction_probabilities, speeds, speed_probabilities

end

function write_windrose_yaml(output_windrose_filepath, directions, direction_probabilities, speeds, speed_probabilities, turbulence_intensity; title="", description="", template_file = "../data/windrose-files/windrose-template.yaml")

    # save wind data to a data structure (from a template)
    data = YAML.load_file(template_file)
    data["title"] = title
    data["description"] = description
    wind_data = data["definitions"]["wind_inflow"]["properties"]
    wind_data["speed"]["bins"] = speeds
    wind_data["speed"]["frequency"] = speed_probabilities
    wind_data["speed"]["minimum"] = minimum(speeds)
    wind_data["speed"]["maximum"] = maximum(speeds)
    wind_data["direction"]["bins"] = directions
    wind_data["direction"]["frequency"] = direction_probabilities
    wind_data["turbulence_intensity"]["default"] = turbulence_intensity

    # write to a yaml file
    write = YAML.write_file(output_windrose_filepath, data)

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
    windrose_directory = "../data/windrose-files/nantucket/"
    input_filename = "nantucket-windrose-ave-speeds.txt"

    # setup and create output file(s)
    for ndirs = ndirs_vec
        output_filename = "nantucket-windrose-ave-speeds-" * lpad(ndirs,3,"0") * "dirs.txt"
        discretize_windrose_single_speed_fromtxt(input_filename, output_filename, ndirs; input_directory=windrose_directory, output_directory=windrose_directory)
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

function create_new_windrose_file_hornsrev(ndirs, nspeeds)

    # set original values for direction and speed joint distribution (from paper by Ju Feng and Wen Zhong Shen, 2015, "Modelling Wind for Wind Farm Layout Optimization Using Joint Distribution of Wind Speed and Wind Direction")
    directions_orig = [0.0, 30.0, 60.0, 90.0, 120.0, 150.0, 180.0, 210.0, 240.0, 270.0, 300.0, 330.0]
    direction_probabilities_orig = [0.0482, 0.0406, 0.0359, 0.0527, 0.0912, 0.0697, 0.0917, 0.1184, 0.1241, 0.1134, 0.117, 0.0969]
    speed_weibull_params_orig = [2.09 8.89; 2.13 9.27; 2.29 8.23; 2.30 9.78; 2.67 11.64; 2.45 11.03; 2.51 11.50; 2.40 11.92; 2.35 11.49; 2.27 11.08; 2.24 11.34; 2.19 10.76]

    # resample discretized wind rose
    directions, direction_probabilities, speeds, speed_probabilities = resample_discretized_windrose_multiple_speeds_weibull(directions_orig, direction_probabilities_orig, speed_weibull_params_orig, ndirs, nspeeds)

    # write to a yaml file
    output_windrose_filepath = "../data/windrose-files/horns-rev/horns-rev-windrose-" * lpad(ndirs, 3, "0") * "dirs-" * lpad(nspeeds, 2, "0") * "speeds.yaml"
    title = "Horns Rev 1 Wind Rose, $ndirs wind directions, $(length(speeds)) wind speeds"
    description = "Wind resource conditions, using direction and speed distribution from the paper by Ju Feng and Wen Zhong Shen: \nModelling Wind for Wind Farm Layout Optimization Using Joint Distribution of Wind Speed and Wind Direction \nhttps://backend.orbit.dtu.dk/ws/portalfiles/portal/110639016/Modelling_Wind_for_Wind_Farm_Layout.pdf"
    turbulence_intensity = 0.75
    write_windrose_yaml(output_windrose_filepath, directions, direction_probabilities, speeds, speed_probabilities, turbulence_intensity, title=title, description=description)

end

# # ---- These are the only value that need to be changed. ----
# create_new_windrose_file = true
# create_new_windrose_plot = true
# ndirs_vec = [10 20 30 40 50 60 70 80 90 100 120 150 200 360]
# # -----------------------------------------------------------

# if create_new_windrose_file
#     create_new_windrose_file_nantucket(ndirs_vec)
# end

# if create_new_windrose_plot
#     create_new_windrose_plot_nantucket(ndirs_vec)
# end

ndirs_vec = [12, 36, 72, 120, 360]
nspeeds_vec = [1, 2, 5, 10, 25, 50]
for ndirs in ndirs_vec
    for nspeeds in nspeeds_vec
        create_new_windrose_file_hornsrev(ndirs, nspeeds)
    end
end