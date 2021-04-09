#################################################################################
# GET INPUT ARGUMENTS
#################################################################################
_ndirs = parse(Int64, ARGS[1])
_nspeeds = parse(Int64, ARGS[2])
_windrose = ARGS[3]
_turbine_type = ARGS[4]
_wake_model = ARGS[5]
_opt_algorithm = ARGS[6]
_opt_algorithm_arg = ARGS[7]
_boundary_shape = ARGS[8]
_boundary_input_arg = ""
try parse(Float64, ARGS[9])
    global _boundary_input_arg = parse(Float64, ARGS[9])
catch
    global _boundary_input_arg = "\"$(ARGS[9])\""
end
_initial_layout_path = ARGS[10]
_final_layout_directory_path = ARGS[11]
_final_layout_file_name = ARGS[12]
_opt_info_directory = ARGS[13]
_final_layout_figure_directory_path = ARGS[14]
_final_layout_figure_file_name = ARGS[15]
_parallel_processing = parse(Bool, ARGS[16])

# create the desired file paths
counter = 1
while !isdir(_final_layout_directory_path) && counter < 100
    try mkpath(_final_layout_directory_path); catch; end
    counter += 1 
end
counter = 1
while !isdir(_final_layout_figure_directory_path) && counter < 100
    try mkpath(_final_layout_figure_directory_path); catch; end
    counter += 1 
end
final_layout_path = _final_layout_directory_path * _final_layout_file_name
final_layout_figure_path = _final_layout_figure_directory_path * _final_layout_figure_file_name


#################################################################################
# IMPORT PACKAGES AND RELEVANT FILES
#################################################################################
using Distributed
using ClusterManagers
using Snopt
using DelimitedFiles 
using PyPlot
import ForwardDiff

ntasks = parse(Int, ENV["SLURM_NTASKS"])
if _parallel_processing
    if ntasks > 1
        addprocs(SlurmManager(ntasks - 1))
    end
    @everywhere import FlowFarm; const ff = FlowFarm
    @everywhere include.(["_aepmodel.jl", "_algorithm.jl", "_boundary.jl", "_farm.jl", "_layout.jl", "_opt.jl", "_plot.jl", "_turbine.jl", "_windrose.jl"])
else
    import FlowFarm; const ff = FlowFarm
    include.(["_aepmodel.jl", "_algorithm.jl", "_boundary.jl", "_farm.jl", "_layout.jl", "_opt.jl", "_plot.jl", "_turbine.jl", "_windrose.jl"])
end



# if _parallel_processing
#     @everywhere _ndirs = $_ndirs
#     @everywhere _nspeeds = $_nspeeds
#     @everywhere _windrose = $_windrose
#     @everywhere _turbine_type = $_turbine_type
#     @everywhere _wake_model = $_wake_model
#     @everywhere _opt_algorithm = $_opt_algorithm
#     @everywhere _opt_algorithm_arg = $_opt_algorithm_arg
#     @everywhere _boundary_shape = $_boundary_shape
#     @everywhere _boundary_input_arg = $_boundary_input_arg
#     @everywhere _initial_layout_path = $_initial_layout_path
#     @everywhere _final_layout_directory_path = $_final_layout_directory_path
#     @everywhere _final_layout_file_name = $_final_layout_file_name
#     @everywhere _opt_info_directory = $_opt_info_directory
#     @everywhere _final_layout_figure_directory_path = $_final_layout_figure_directory_path
#     @everywhere _final_layout_figure_file_name = $_final_layout_figure_file_name
#     @everywhere _parallel_processing = $_parallel_processing
# end


#################################################################################
# SET LAYOUT PARAMETERS
#################################################################################
layout_param = layout_set(_initial_layout_path)
nturbines = length(layout_param.turbine_x)


#################################################################################
# SET MODEL PARAMETERS
#################################################################################
model_param = model_set(_wake_model, _turbine_type, nturbines, _windrose, _ndirs, _nspeeds)


#################################################################################
# SET OPTIMIZATION ALGORITHM
#################################################################################
eval(Meta.parse("opt_algorithm = $(_opt_algorithm)($_opt_algorithm_arg, $_parallel_processing)"))


#################################################################################
# SET FARM BOUNDARY
#################################################################################
eval(Meta.parse("farm_boundary = $(_boundary_shape)($(_boundary_input_arg))"))


#################################################################################
# TRANSFER MODEL PARAMETERS TO EACH CORE (IF PARALLEL PROCESSING IS USED)
#################################################################################
if _parallel_processing
    @everywhere layout_param = $layout_param
    @everywhere model_param = $model_param
    @everywhere opt_algorithm = $opt_algorithm
    @everywhere farm_boundary = $farm_boundary
end

#################################################################################
# DEFINE OPTIMIZATION FUNCTIONS
#################################################################################

if opt_algorithm.parallel_processing

    # set up objective wrapper function
    @everywhere function obj_with_TI(x, layout_param, model_param, opt_algorithm::SnoptWECAlgorithm)

        # get number of turbines
        nturbines = Int(length(x)/2)

        # extract x and y locations of turbines from design variables vector
        turbine_x = x[1:nturbines] 
        turbine_y = x[nturbines+1:end]

        # calculate AEP
        AEP = opt_algorithm.objscale*ff.calculate_aep(turbine_x, turbine_y, layout_param.base_heights, model_param.turbine_design.rotor_diameter,
                    model_param.turbine_design.hub_height, model_param.turbine_op.yaw, model_param.turbine_ct_models, model_param.turbine_design.generator_efficiency, model_param.turbine_design.cut_in_speed,
                    model_param.turbine_design.cut_out_speed, model_param.turbine_design.rated_speed, model_param.turbine_design.rated_power, model_param.wind_resource_model, model_param.turbine_power_models, model_param.farm_model_with_ti,
                    rotor_sample_points_y=model_param.velocity_sampling.rotor_sample_points_y, rotor_sample_points_z=model_param.velocity_sampling.rotor_sample_points_z)
        
        # return the objective as an array
        return [AEP]
    end

    @everywhere function obj_no_TI(x, layout_param, model_param, opt_algorithm::SnoptWECAlgorithm)

        # get number of turbines
        nturbines = Int(length(x)/2)

        # extract x and y locations of turbines from design variables vector
        turbine_x = x[1:nturbines] 
        turbine_y = x[nturbines+1:end]

        # calculate AEP
        AEP = opt_algorithm.objscale*ff.calculate_aep(turbine_x, turbine_y, layout_param.base_heights, model_param.turbine_design.rotor_diameter,
                    model_param.turbine_design.hub_height, model_param.turbine_op.yaw, model_param.turbine_ct_models, model_param.turbine_design.generator_efficiency, model_param.turbine_design.cut_in_speed,
                    model_param.turbine_design.cut_out_speed, model_param.turbine_design.rated_speed, model_param.turbine_design.rated_power, model_param.wind_resource_model, model_param.turbine_power_models, model_param.farm_model_no_ti,
                    rotor_sample_points_y=model_param.velocity_sampling.rotor_sample_points_y, rotor_sample_points_z=model_param.velocity_sampling.rotor_sample_points_z)

        # return the objective as an array
        return [AEP]
    end

else

    # set up objective wrapper function
    function obj_with_TI(x)

        # get number of turbines
        nturbines = Int(length(x)/2)

        # extract x and y locations of turbines from design variables vector
        turbine_x = x[1:nturbines] 
        turbine_y = x[nturbines+1:end]

        # calculate AEP
        AEP = opt_algorithm.objscale*ff.calculate_aep(turbine_x, turbine_y, layout_param.base_heights, model_param.turbine_design.rotor_diameter,
                    model_param.turbine_design.hub_height, model_param.turbine_op.yaw, model_param.turbine_ct_models, model_param.turbine_design.generator_efficiency, model_param.turbine_design.cut_in_speed,
                    model_param.turbine_design.cut_out_speed, model_param.turbine_design.rated_speed, model_param.turbine_design.rated_power, model_param.wind_resource_model, model_param.turbine_power_models, model_param.farm_model_with_ti,
                    rotor_sample_points_y=model_param.velocity_sampling.rotor_sample_points_y, rotor_sample_points_z=model_param.velocity_sampling.rotor_sample_points_z)
        
        # return the objective as an array
        return [AEP]
    end

    function obj_no_TI(x)

        # get number of turbines
        nturbines = Int(length(x)/2)

        # extract x and y locations of turbines from design variables vector
        turbine_x = x[1:nturbines] 
        turbine_y = x[nturbines+1:end]

        # calculate AEP
        AEP = opt_algorithm.objscale*ff.calculate_aep(turbine_x, turbine_y, layout_param.base_heights, model_param.turbine_design.rotor_diameter,
                    model_param.turbine_design.hub_height, model_param.turbine_op.yaw, model_param.turbine_ct_models, model_param.turbine_design.generator_efficiency, model_param.turbine_design.cut_in_speed,
                    model_param.turbine_design.cut_out_speed, model_param.turbine_design.rated_speed, model_param.turbine_design.rated_power, model_param.wind_resource_model, model_param.turbine_power_models, model_param.farm_model_no_ti,
                    rotor_sample_points_y=model_param.velocity_sampling.rotor_sample_points_y, rotor_sample_points_z=model_param.velocity_sampling.rotor_sample_points_z)

        # return the objective as an array
        return [AEP]
    end

end

obj_with_TI(x) = obj_with_TI(x, layout_param, model_param, opt_algorithm)
obj_no_TI(x) = obj_no_TI(x, layout_param, model_param, opt_algorithm)

# set up constraint wrapper function
function con(x, model_param, boundary)

    # get number of turbines
    nturbines = Int(length(x)/2)
    
    # extract x and y locations of turbines from design variables vector
    turbine_x = x[1:nturbines]
    turbine_y = x[nturbines+1:end]

    # get constraint values
    spacing_con = 2.0*model_param.turbine_design.rotor_diameter[1] .- ff.turbine_spacing(turbine_x,turbine_y)
    boundary_con = ff.ray_trace_boundary(boundary.vertices, boundary.normals, turbine_x, turbine_y)
    
    return [spacing_con; boundary_con]
end

con(x) = con(x, model_param, farm_boundary)

# set up optimization problem wrapper function
function wind_farm_opt_with_TI(x)

    # calculate the objective and jacobian (negative sign in order to maximize AEP)
    AEP = -obj_with_TI(x)[1]
    dAEP_dx = -ForwardDiff.jacobian(obj_with_TI, x)

    # calculate constraint and jacobian
    c = con(x)
    dc_dx = ForwardDiff.jacobian(con, x)

    # set fail flag to false
    fail = false

    # return objective, constraint, and jacobian values
    return AEP, c, dAEP_dx, dc_dx, fail
end

function wind_farm_opt_no_TI(x)

    # calculate the objective and jacobian (negative sign in order to maximize AEP)
    AEP = -obj_no_TI(x)[1]
    dAEP_dx = -ForwardDiff.jacobian(obj_no_TI, x)

    # calculate constraint and jacobian
    c = con(x)
    dc_dx = ForwardDiff.jacobian(con, x)

    # set fail flag to false
    fail = false

    # return objective, constraint, and jacobian values
    return AEP, c, dAEP_dx, dc_dx, fail
end

#################################################################################
# RUN OPTIMIZATION
#################################################################################
turbine_x_opt, turbine_y_opt = optimize_farm_layout(wind_farm_opt_with_TI, wind_farm_opt_no_TI, final_layout_path, _opt_info_directory, layout_param, model_param, opt_algorithm, farm_boundary)

#################################################################################
# PLOT LAYOUT
#################################################################################
plot_initial_final_layout([layout_param.turbine_x; layout_param.turbine_y], [turbine_x_opt; turbine_y_opt], turbine_design, farm_boundary, save_fig=true, path_to_fig_file=final_layout_figure_path)