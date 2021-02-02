using Snopt
using DelimitedFiles 
using PyPlot
import ForwardDiff

# variables to get from SLURM: layout_number, ndirs
layout_number = Base.parse(Int, ENV["layout_number"])
ndirs = Base.parse(Int, ENV["ndirs"])

# set directory and file names (must do this before including the model set file)
layout_directory = "initial-layouts/"
layout_filename = "initial-layout-9turb-circular-" * lpad(layout_number,3,"0") * ".txt"
windrose_directory = "windrose-files/"
windrose_filename = "nantucket-windrose-ave-speeds-" * lpad(ndirs,3,"0") * "dirs.txt"
output_layout_directory = "final-layouts/9turb-circular/"
output_layout_filename = "final-layout-9turb-circular-" * lpad(ndirs,3,"0") * "dirs-" * lpad(layout_number,3,"0") * "-wec.txt"
output_wec_layouts = "final-layout-9turb-circular-" * lpad(ndirs,3,"0") * "dirs-" * lpad(layout_number,3,"0") * "-weclayouthistory.txt"

# set up boundary constraint wrapper function
function boundary_wrapper(x, params)
    # include relevant globals
    params.boundary_center
    params.boundary_radius

    # get number of turbines
    nturbines = Int(length(x)/2)
    
    # extract x and y locations of turbines from design variables vector
    turbine_x = x[1:nturbines]
    turbine_y = x[nturbines+1:end]

    # get and return boundary distances
    return ff.circle_boundary(boundary_center, boundary_radius, turbine_x, turbine_y)
end

# set up spacing constraint wrapper function
function spacing_wrapper(x, params)
    # include relevant globals
    params.rotor_diameter

    # get number of turbines
    nturbines = Int(length(x)/2)

    # extract x and y locations of turbines from design variables vector
    turbine_x = x[1:nturbines]
    turbine_y = x[nturbines+1:end]

    # get and return spacing distances
    return 2.0*rotor_diameter[1] .- ff.turbine_spacing(turbine_x,turbine_y)
end

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

# set up optimization problem wrapper function
function wind_farm_opt(x)

    # calculate spacing constraint value and jacobian
    spacing_con = spacing_wrapper(x)
    ds_dx = ForwardDiff.jacobian(spacing_wrapper, x)

    # calculate boundary constraint and jacobian
    boundary_con = boundary_wrapper(x)
    db_dx = ForwardDiff.jacobian(boundary_wrapper, x)

    # combine constaint values and jacobians into overall constaint value and jacobian arrays
    c = [spacing_con; boundary_con]
    dcdx = [ds_dx; db_dx]

    # calculate the objective function and jacobian (negative sign in order to maximize AEP)
    AEP = -aep_wrapper(x)[1]
    dAEP_dx = -ForwardDiff.jacobian(aep_wrapper,x)

    # set fail flag to false
    fail = false

    # return objective, constraint, and jacobian values
    return AEP, c, dAEP_dx, dcdx, fail
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

# import model set with wind farm and related details
include("model-sets/model_set_9turb_round_farm.jl")

# scale objective to be between 0 and 1
obj_scale = 1E-11

# set wind farm boundary parameters
boundary_center = [0.0,0.0]
boundary_radius = 450.0

# initialize struct for opt params
params = params_struct2(model_set, rotor_points_y, rotor_points_z, turbine_z, 
    rotor_diameter, boundary_center, boundary_radius, obj_scale, hub_height, turbine_yaw, 
    ct_models, generator_efficiency, cut_in_speed, cut_out_speed, rated_speed, rated_power, 
    windresource, power_models)

# initialize design variable array
x = [copy(turbine_x);copy(turbine_y)]
xinit = deepcopy(x)
# report initial objective value
initial_obj = aep_wrapper(x, params)[1]
println("starting objective value: ", aep_wrapper(x, params)[1])

# add initial turbine location to plot
for i = 1:length(turbine_x)
    plt.gcf().gca().add_artist(plt.Circle((turbine_x[i],turbine_y[i]), rotor_diameter[1]/2.0, fill=false,color="C0"))
end

# set general lower and upper bounds for design variables
lb = zeros(length(x)) .- boundary_radius
ub = zeros(length(x)) .+ boundary_radius

# set up options for SNOPT
options = Dict{String, Any}()
options["Derivative option"] = 1
options["Verify level"] = 3
options["Major optimality tolerance"] = 5e-5
options["Major iteration limit"] = 1e6

# set up for WEC optimization
wec_steps = 6
wec_max = 3.0
wec_end = 1.0
wec_values = collect(LinRange(wec_max, wec_end, wec_steps))

# initialize xopt array
noptimizations = wec_steps + 2
xopt_all = zeros(2*nturbines,noptimizations)
xopt_all[:,1] = [deepcopy(turbine_x);deepcopy(turbine_y)]
x = [deepcopy(turbine_x);deepcopy(turbine_y)]

# generate wrapper function surrogates
spacing_wrapper(x) = spacing_wrapper(x, params)
aep_wrapper(x) = aep_wrapper(x, params)
boundary_wrapper(x) = boundary_wrapper(x, params)
obj_func(x) = wind_farm_opt(x)

# run optimizations
for i = 1:length(wec_values)
    params.model_set.wake_deficit_model.wec_factor[1] = wec_values[i]
    println("Now running with WEC = ", round(params.model_set.wake_deficit_model.wec_factor[1],digits=1), " and no local TI")
    options["Summary file"] = "opt-out-files/" * lpad(ndirs,3,"0") * "dirs/" * "snopt-opt-" * lpad(ndirs,3,"0") * "dirs-" * lpad(layout_number,3,"0") * "-wec" * rpad(round(wec_values[i],digits=1),3,"0") * "-nolocalTI-summary.out"
    options["Print file"] = "opt-out-files/" * lpad(ndirs,3,"0") * "dirs/" * "snopt-opt-" * lpad(ndirs,3,"0") * "dirs-" * lpad(layout_number,3,"0") * "-wec" * rpad(round(wec_values[i],digits=1),3,"0") * "-nolocalTI-print.out"
    xopt_all[:,i+1], fopt, info = snopt(obj_func, x, lb, ub, options)
end

localtimodel = ff.LocalTIModelMaxTI()
model_set = ff.WindFarmModelSet(wakedeficitmodel, wakedeflectionmodel, wakecombinationmodel, localtimodel)
options["Summary file"] = "opt-out-files/" * lpad(ndirs,3,"0") * "dirs/" * "snopt-opt-" * lpad(ndirs,3,"0") * "dirs-" * lpad(layout_number,3,"0") * "-wec" * rpad(round(wec_values[end],digits=1),3,"0") * "-summary.out"
options["Print file"] = "opt-out-files/" * lpad(ndirs,3,"0") * "dirs/" * "snopt-opt-" * lpad(ndirs,3,"0") * "dirs-" * lpad(layout_number,3,"0") * "-wec" * rpad(round(wec_values[end],digits=1),3,"0") * "-print.out"
println("Now running with WEC = ", round(params.model_set.wake_deficit_model.wec_factor[1],digits=1), " with local TI")
xopt_all[:,end], fopt, info = snopt(obj_func, x, lb, ub, options)

# print optimization results
println("info: ", info)
xopt = xopt_all[:,end]
final_obj = aep_wrapper(xopt)[1]
println("end objective value: ", final_obj)

# extract final turbine locations
turbine_x = copy(xopt[1:nturbines])
turbine_y = copy(xopt[nturbines+1:end])

# save final layout to YAML
ff.write_turb_loc_YAML(output_layout_directory * output_layout_filename, turbine_x, turbine_y; 
    title="Optimized $nturbines-turbine layout for a circular boundary wind farm. Layout: $layout_number", 
    titledescription="Contains optimized coordinates for $nturbines turbines arranged in a circular boundary wind farm with a boundary radius of $boundary_radius m. The farm is centered at the coordinate ($(boundary_center[1]), $(boundary_center[2])). Each turbine has a rotor diameter of $rotor_diameter m.", 
    turbinefile="input-files/NREL5MWCPCT.txt", locunits="m", wakemodelused="Bastankhah and Porté-Agel (2016)", windresourcefile="windrose-files/nantucket-windrose-ave-speeds-" * lpad(ndirs,3,"0") * "dirs.txt", aeptotal=final_obj*1e-6/params.obj_scale, 
    aepdirs=ndirs, aepunits="MWh", baseyaml="initial-layouts/default_turbine_layout.yaml")

# save WEC layout history to txt file
open(output_layout_directory * output_wec_layouts, "w") do io
    write(io, "# initial, wec=3.0, wec=2.6, wec=2.2, wec=1.8, wec=1.4, wec=1.0, wec=1.0_withlocTI\n")
    writedlm(io, xopt_all)
end

# add final turbine locations to plot
for i = 1:length(turbine_x)
    plt.gcf().gca().add_artist(plt.Circle((turbine_x[i],turbine_y[i]), rotor_diameter[1]/2.0, fill=false,color="C1", linestyle="--")) 
end

# add wind farm boundary to plot
plt.gcf().gca().add_artist(plt.Circle((boundary_center[1],boundary_center[2]), boundary_radius, fill=false,color="C2"))

# set up and show plot
axis("square")
xlim(-boundary_radius-200,boundary_radius+200)
ylim(-boundary_radius-200,boundary_radius+200)
plt.show()
