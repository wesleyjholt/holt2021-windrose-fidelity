using YAML
using PyPlot

# set up objective wrapper function
function aep_wrapper(x, params)

    # get number of turbines
    nturbines = Int(length(x)/2)

    # extract x and y locations of turbines from design variables vector
    turbine_x = x[1:nturbines] 
    turbine_y = x[nturbines+1:end]

    # calculate AEP
    AEP = obj_scale*ff.calculate_aep(turbine_x, turbine_y, params.turbine_z, params.rotor_diameter,
                params.hub_height, params.turbine_yaw, params.ct_models, params.generator_efficiency, params.cut_in_speed,
                params.cut_out_speed, params.rated_speed, params.rated_power, params.windresource, params.power_models, params.model_set,
                rotor_sample_points_y=params.rotor_points_y,rotor_sample_points_z=params.rotor_points_z)
    
    # return the objective as an array
    return [AEP]
end

# set globals for use in wrapper functions
struct params_struct2{MS, AF, F, I, ACTM, WR, APM}
    model_set::MS
    rotor_points_y::AF
    rotor_points_z::AF
    turbine_z::AF
    rotor_diameter::AF
    boundary_center::AF
    boundary_radius::F
    obj_scale::I
    hub_height::AF
    turbine_yaw::AF
    ct_models::ACTM
    generator_efficiency::AF
    cut_in_speed::AF
    cut_out_speed::AF
    rated_speed::AF
    rated_power::AF
    windresource::WR
    power_models::APM
end

# set ndirs and layout number
ndirs = 360 # this number matters for the analysis
layout_number = 1 # this number doesn't matter
farm = "9turb-circle-450r"

# set directory and file names (must do this before including the model set file)
layout_directory = "initial-layouts/9turb-circle-450radius/"
layout_filename = "initial-layout-9turb-circular-" * lpad(layout_number,3,"0") * ".txt"
windrose_directory = "windrose-files/nantucket/"
windrose_filename = "nantucket-windrose-ave-speeds-" * lpad(ndirs,3,"0") * "dirs.txt"

# import model set with wind farm and related details
include("model-sets/model_set_9turb_round_farm.jl")

# scale objective to be between 0 and 1
obj_scale = 1E-6

# set wind farm boundary parameters
boundary_center = [0.0,0.0]
if farm=="9turb-circle-600r"
    boundary_radius = 600.0
elseif farm=="9turb-circle-450r"
    boundary_radius = 450.0
end

# initialize struct for opt params
params = params_struct2(model_set, rotor_points_y, rotor_points_z, turbine_z, 
    rotor_diameter, boundary_center, boundary_radius, obj_scale, hub_height, turbine_yaw, 
    ct_models, generator_efficiency, cut_in_speed, cut_out_speed, rated_speed, rated_power, 
    windresource, power_models)


#---- analyze final layouts ----

plot=true

initial_layout_directory = "initial-layouts/9turb-circle-450r/"

nlayouts = 20
ndirs_vec = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150, 200, 360]

aeps_initial_layouts = zeros(nlayouts, length(ndirs_vec))
aeps_initial_layouts_360dirs = zeros(nlayouts, length(ndirs_vec))
aeps_final_layouts = zeros(nlayouts, length(ndirs_vec))
aeps_final_layouts_360dirs = zeros(nlayouts, length(ndirs_vec))

for layout_number = 1:nlayouts
    for (i, ndirs_reference) in enumerate(ndirs_vec)
        final_layout_directory = "final-layouts/" * farm * "/" * lpad(ndirs_reference,3,"0") * "dirs/"
        initial_layout_filename = "initial-layout-9turb-circular-" * lpad(layout_number,3,"0") * ".txt"
        final_layout_filename = "final-layout-" * lpad(layout_number,3,"0") * "-wec.yaml"
        final_data = YAML.load_file(final_layout_directory * final_layout_filename)
        aeps[layout_number,i] = final_data["definitions"]["plant_energy"]["properties"]["annual_energy_production"]["default"]
        nturbines = length(final_data["definitions"]["position"]["items"])
        layout = zeros(nturbines*2)
        for i = 1:2, j = 1:nturbines
            layout[(i-1)*nturbines+j] = final_data["definitions"]["position"]["items"][j][i]
        end
        aeps_360dirs[layout_number,i] = aep_wrapper(layout, params)[1]
        if plot
        end
    end
end

display(aeps)
print("\n\n")
display(aeps_360dirs)
print("\n\n")
aep_error = (aeps .- aeps_360dirs) ./ aeps_360dirs
display(aep_error)

fig = plt.figure()
ax = fig.add_axes([0.15, 0.1, 0.8, 0.8])
plt.boxplot(aeps)
plt.title("AEP for 9-turbine circular farm \n($nlayouts for each wind rose)")
plt.xlabel("Number of Wind Directions")
plt.ylabel("AEP (MWh)")
ax.set_xticklabels(ndirs_vec)
savefig("final-layouts/figures/aepboxplots-" * farm * "-$nlayouts-layouts", dpi=600)
# plt.show()

fig = plt.figure()
ax = fig.add_axes([0.15, 0.1, 0.8, 0.8])
plt.boxplot(aeps_360dirs)
plt.title("AEP for 9-turbine circular farm calculated with 360 directions \n($nlayouts for each wind rose)")
plt.xlabel("Number of Wind Directions")
plt.ylabel("AEP (MWh)")
ax.set_xticklabels(ndirs_vec)
savefig("final-layouts/figures/aepboxplots-" * farm * "-recalcaep-$nlayouts-layouts", dpi=600)
# plt.show()

fig = plt.figure()
ax = fig.add_axes([0.15, 0.1, 0.8, 0.8])
plt.boxplot(aep_error)
plt.title("AEP Error for 9-turbine circular farm (compared with 360 directions) \n($nlayouts for each wind rose)")
plt.xlabel("Number of Wind Directions")
plt.ylabel("AEP (MWh)")
ax.set_xticklabels(ndirs_vec)
savefig("final-layouts/figures/aepboxplots-" * farm * "-aeperror-$nlayouts-layouts", dpi=600)
# plt.show()