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
mkpath(_final_layout_directory_path)
mkpath(_final_layout_figure_directory_path)
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

if _parallel_processing
    addprocs(SlurmManager(parse(Int, ENV["SLURM_NTASKS"])-1))
    @everywhere import FlowFarm; const ff=FlowFarm
    @everywhere include.(["_aepmodel.jl", "_algorithm.jl", "_boundary.jl", "_farm.jl", "_layout.jl", "_opt.jl", "_plot.jl", "_turbine.jl", "_windrose.jl"])
else
    import FlowFarm; const ff=FlowFarm
    include.(["_aepmodel.jl", "_algorithm.jl", "_boundary.jl", "_farm.jl", "_layout.jl", "_opt.jl", "_plot.jl", "_turbine.jl", "_windrose.jl"])
end

if _parallel_processing
    @everywhere _ndirs = $_ndirs
    @everywhere _nspeeds = $_nspeeds
    @everywhere _windrose = $_windrose
    @everywhere _turbine_type = $_turbine_type
    @everywhere _wake_model = $_wake_model
    @everywhere _opt_algorithm = $_opt_algorithm
    @everywhere _opt_algorithm_arg = $_opt_algorithm_arg
    @everywhere _boundary_shape = $_boundary_shape
    @everywhere _boundary_input_arg = $_boundary_input_arg
    @everywhere _initial_layout_path = $_initial_layout_path
    @everywhere _final_layout_directory_path = $_final_layout_directory_path
    @everywhere _final_layout_file_name = $_final_layout_file_name
    @everywhere _opt_info_directory = $_opt_info_directory
    @everywhere _final_layout_figure_directory_path = $_final_layout_figure_directory_path
    @everywhere _final_layout_figure_file_name = $_final_layout_figure_file_name
    @everywhere _parallel_processing = $_parallel_processing
end


#################################################################################
# SET LAYOUT PARAMETERS
#################################################################################
if _parallel_processing
    @everywhere layout_param = layout_set(_initial_layout_path)
    @everywhere nturbines = length(layout_param.turbine_x)
else
    layout_param = layout_set(_initial_layout_path)
    nturbines = length(layout_param.turbine_x)
end

#################################################################################
# SET MODEL PARAMETERS
#################################################################################
if _parallel_processing
    @everywhere model_param = model_set(_wake_model, _turbine_type, nturbines, _windrose, _ndirs, _nspeeds)
else
    model_param = model_set(_wake_model, _turbine_type, nturbines, _windrose, _ndirs, _nspeeds)
end


#################################################################################
# SET OPTIMIZATION ALGORITHM
#################################################################################
if _parallel_processing
    @everywhere eval(Meta.parse("opt_algorithm = $(_opt_algorithm)($_opt_algorithm_arg, $_parallel_processing)"))
else
    eval(Meta.parse("opt_algorithm = $(_opt_algorithm)($_opt_algorithm_arg, $_parallel_processing)"))
end


#################################################################################
# SET FARM BOUNDARY
#################################################################################
eval(Meta.parse("farm_boundary = $(_boundary_shape)($(_boundary_input_arg))"))


#################################################################################
# RUN OPTIMIZATION
#################################################################################
println("Did we get here?")
turbine_x_opt, turbine_y_opt = optimize_farm_layout(final_layout_path, _opt_info_directory, layout_param, model_param, opt_algorithm, farm_boundary)
println("How abount here?")

#################################################################################
# PLOT LAYOUT
#################################################################################
plot_initial_final_layout([layout_param.turbine_x; layout_param.turbine_y], [turbine_x_opt; turbine_y_opt], turbine_design, farm_boundary, save_fig=true, path_to_fig_file=final_layout_figure_path)