using YAML
using PyPlot
using DelimitedFiles

#---- analyze final layouts ----

plot=true

farm = "9turb-circle-600radius"
rotor_diameter = 126.4
boundary_center = [0.0,0.0]
boundary_radius = 600

initial_layout_directory = "initial-layouts/9turb-circle-450radius/"

nlayouts = 20
ndirs_vec = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150, 200, 360]

aeps = zeros(nlayouts, length(ndirs_vec))
aeps_360dirs = zeros(nlayouts, length(ndirs_vec))

for layout_number = 1:nlayouts
    for (i, ndirs_reference) in enumerate(ndirs_vec)
        final_layout_directory = "final-layouts/" * farm * "/" * lpad(ndirs_reference,3,"0") * "dirs/"
        initial_layout_filename = "initial-layout-9turb-circular-" * lpad(layout_number,3,"0") * ".txt"
        final_layout_filename = "final-layout-" * lpad(layout_number,3,"0") * "-wec.yaml"
        final_data = YAML.load_file(final_layout_directory * final_layout_filename)
        # aeps[layout_number,i] = final_data["definitions"]["plant_energy"]["properties"]["annual_energy_production"]["default"]
        nturbines = length(final_data["definitions"]["position"]["items"])
        layout = zeros(nturbines*2)
        for i = 1:2, j = 1:nturbines
            layout[(i-1)*nturbines+j] = final_data["definitions"]["position"]["items"][j][i]
        end
        # aeps_360dirs[layout_number,i] = aep_wrapper(layout, params)[1]
        if plot
            clf()
            # import the initial layout file
            initial_turbine_locations = readdlm(initial_layout_directory * initial_layout_filename, skipstart=1)
            turbine_x_initial = initial_turbine_locations[:,1]
            turbine_y_initial = initial_turbine_locations[:,2]

            # add initial turbine location to plot
            for i = 1:nturbines
                plt.gcf().gca().add_artist(plt.Circle((turbine_x_initial[i],turbine_y_initial[i]), rotor_diameter[1]/2.0, fill=false, color="C0", linestyle="--"))
            end

            turbine_x_final = layout[1:nturbines]
            turbine_y_final = layout[nturbines+1:end]

            # add final turbine locations to plot
            for i = 1:nturbines
                plt.gcf().gca().add_artist(plt.Circle((turbine_x_final[i],turbine_y_final[i]), rotor_diameter[1]/2.0, fill=false, color="C1")) 
            end

            # add wind farm boundary to plot
            plt.gcf().gca().add_artist(plt.Circle((boundary_center[1],boundary_center[2]), boundary_radius, fill=false,color="C2"))

            # set up and show plot
            axis("square")
            xlim(-boundary_radius-200,boundary_radius+200)
            ylim(-boundary_radius-200,boundary_radius+200)
            savefig("final-layouts/" * farm * "-figures/" * lpad(ndirs_reference,3,"0") * "dirs/final-layout-" * lpad(layout_number,3,"0") * "wec.png", dpi=600)
        end
    end
end