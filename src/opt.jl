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
_wake_model = ARGS[3]
_turbine_type = ARGS[4]
_windrose = ARGS[5]
_opt_algorithm = ARGS[6]
_boundary_shape = ARGS[7]
_boundary_input_arg = ""
try parse(Float64, ARGS[8])
    global _boundary_input_arg = parse(Float64, ARGS[8])
catch
    global _boundary_input_arg = ARGS[8]
end
_initial_layout_path = ARGS[9]
_final_layout_path = ARGS[10]
_opt_info_directory = ARGS[11]
_final_layout_figure_path = ARGS[12]


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
eval(Meta.parse("opt_algorithm = $(_opt_algorithm)()"))


#################################################################################
# SET FARM BOUNDARY
#################################################################################
eval(Meta.parse("farm_boundary = $(_boundary_shape)($(_boundary_input_arg))"))


#################################################################################
# RUN OPTIMIZATION
#################################################################################
turbine_x_opt, turbine_y_opt = run_opt(_final_layout_path, _opt_info_directory, layout_param, model_param, opt_algorithm, farm_boundary)


#################################################################################
# PLOT LAYOUT
#################################################################################
plot_initial_final_layout([layout_param.turbine_x; layout_param.turbine_y], [turbine_x_opt; turbine_y_opt], turbine_design, farm_boundary, save_fig=true)