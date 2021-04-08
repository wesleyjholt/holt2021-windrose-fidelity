#################################################################################
# IMPORT PACKAGES AND RELEVANT FILES
#################################################################################
import FlowFarm; const ff=FlowFarm
using Snopt
using DelimitedFiles 
using PyPlot
import ForwardDiff

include.(["_aepmodel.jl", "_algorithm.jl", "_boundary.jl", "_farm.jl", "_layout.jl", "_opt.jl", "_plot.jl", "_turbine.jl", "_windrose.jl"])


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
eval(Meta.parse("opt_algorithm = $(_opt_algorithm)($_opt_algorithm_arg)"))


#################################################################################
# SET FARM BOUNDARY
#################################################################################
eval(Meta.parse("farm_boundary = $(_boundary_shape)($(_boundary_input_arg))"))


#################################################################################
# RUN OPTIMIZATION
#################################################################################
turbine_x_opt, turbine_y_opt = optimize_farm_layout(final_layout_path, _opt_info_directory, layout_param, model_param, opt_algorithm, farm_boundary)


#################################################################################
# PLOT LAYOUT
#################################################################################
plot_initial_final_layout([layout_param.turbine_x; layout_param.turbine_y], [turbine_x_opt; turbine_y_opt], turbine_design, farm_boundary, save_fig=true, path_to_fig_file=final_layout_figure_path)