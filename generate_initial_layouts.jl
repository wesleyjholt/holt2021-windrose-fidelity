# This file is for generating intial turbine layouts.

import FlowFarm; const ff = FlowFarm
using PyPlot
using DelimitedFiles

function generate_random_layout_circle_boundary(layout_filename, nturbines, rotor_diameter, boundary_center, boundary_radius; layout_directory="", min_spacing=1.0, layout_number=0)
    
    # set bounding box
    xrange = [boundary_center[1] - boundary_radius; boundary_center[1] + boundary_radius]
    yrange = [boundary_center[2] - boundary_radius; boundary_center[2] + boundary_radius]

    # scale the minimum spacing
    min_spacing *= rotor_diameter

    # generate random points within the wind farm boundary
    locations = zeros(Float64, nturbines, 2)
    count = 0
    for i = 1:nturbines
        good_point = false
        while !good_point && count < 1e8
            if mod(count,1e5)==0
                println("count: ", count)
            end
            count += 1
            # generate random point in the containing rectangle
            locations[i,:] = (rand(1,2) .- 0.5).*[xrange[2]-xrange[1] yrange[2]-yrange[1]] .+ boundary_center
            # println("random point: ", locations[i,:])
            distances = ff.circle_boundary(boundary_center, boundary_radius, locations[1:i,1], locations[1:i,2])
            # println("constraint value: ", distances)
            # determine if the point is inside the wind farm boundary
            good_point = true
            for j = 1:length(distances)
                if distances[j] > 0.0
                    good_point = false
                end
            end
            # determine if the point is far enough away from other points
            n_bad_spacings = 0.0
            for turb = 1:nturbines
                if turb != i
                    spacing = sqrt((locations[turb,1]-locations[i,1])^2 + (locations[turb,2]-locations[i,2])^2)
                    if spacing < min_spacing
                        n_bad_spacings += 1
                    end
                end
                if n_bad_spacings > 0
                    good_point = false
                end
            end
        end
    end

    turbine_x = locations[:,1]
    turbine_y = locations[:,2]
    
    # # save initial layout to YAML
    # ff.write_turb_loc_YAML(layout_directory * layout_filename, turbine_x, turbine_y; 
    # title="Randomly generated $nturbines-turbine layout for a circular boundary wind farm. Layout: $layout_number", 
    # titledescription="Contains randomly generated coordinates for $nturbines turbines arranged in a circular boundary wind farm with a boundary radius of $boundary_radius m. The farm is centered at the coordinate ($(boundary_center[1]), $(boundary_center[2])). Each turbine has a rotor diameter of $rotor_diameter m.", 
    # turbinefile="", locunits="m", wakemodelused="", windresourcefile="", aeptotal=[], 
    # aepdirs=[], aepunits="MWh", baseyaml="initial-layouts/default_turbine_layout.yaml")

    # write out interpolated wind rose file
    open(layout_directory * layout_filename, "w") do io
        write(io, "# turbine_x, turbine_y\n")
        writedlm(io, [turbine_x turbine_y])
    end

end

function plot_initial_layout_circle(figure_filename, layout_filename, rotor_diameter, boundary_center, boundary_radius; figure_directory="", layout_directory="", save_fig=true, show_fig=false)

    # import turbine coordinates
    # layout_filedata = ff.get_turb_loc_YAML(layout_directory * layout_filename)
    turbine_locations = readdlm(layout_directory * layout_filename, skipstart=1)
    turbine_x = turbine_locations[:,1]
    turbine_y = turbine_locations[:,2]

    # plot turbine locations
    clf()
    for i = 1:length(turbine_x)
        plt.gcf().gca().add_artist(plt.Circle((turbine_x[i],turbine_y[i]), rotor_diameter[1]/2.0, fill=false, color="C0", linestyle="--")) 
    end

    # add wind farm boundary to plot
    plt.gcf().gca().add_artist(plt.Circle((boundary_center[1],boundary_center[2]), boundary_radius, fill=false,color="C2"))

    # set figure axes
    axis("square")
    xlim(-boundary_radius-100,boundary_radius+100)
    ylim(-boundary_radius-100,boundary_radius+100)

    # save figure (if specified)
    if save_fig
        savefig(figure_directory * figure_filename)
    end

    # show figure (if specified)
    if show_fig
        plt.show()
    end

end

generate_layout_file = true
generate_layout_figure = true

# set up the inputs to the generate layouts function
layout_directory = "initial-layouts/"
figure_directory = "initial-layouts/initial-layouts-figures/"
nturbines = 9
rotor_diameter = 126.4
boundary_center = [0.0 0.0]
boundary_radius = 450.0

# set how many layouts to generate/plot
start_layout_number = 1
end_layout_number = 100
layout_numbers = range(start_layout_number, stop=end_layout_number, step=1)

if generate_layout_file
    # iterate through each layout
    for layout_number = layout_numbers
        layout_filename = "initial-layout-9turb-circular-" * lpad(layout_number,3,"0") * ".txt"
        generate_random_layout_circle_boundary(layout_filename, nturbines, rotor_diameter, boundary_center, boundary_radius; layout_directory=layout_directory, min_spacing=1.8, layout_number=layout_number)
    end
end

if generate_layout_figure
    # iterate through each layout
    for layout_number = layout_numbers
        layout_filename = "initial-layout-9turb-circular-" * lpad(layout_number,3,"0") * ".txt"
        figure_filename = "initial-layout-9turb-circular-" * lpad(layout_number,3,"0") * ".png"
        plot_initial_layout_circle(figure_filename, layout_filename, rotor_diameter, boundary_center, boundary_radius; figure_directory=figure_directory, layout_directory=layout_directory)
    end
end