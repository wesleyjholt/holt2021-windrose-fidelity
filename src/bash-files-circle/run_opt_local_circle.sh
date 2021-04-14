#!/bin/sh

#######################################################################################
# THIS FILE RUNS A SINGLE OPTIMIZATION FOR THE SPECIFIED LAYOUT AND SET OF PARAMETERS.
#######################################################################################

# The number of cores and layout number goes here.
export SLURM_NTASKS=1
SLURM_ARRAY_TASK_ID=04

# The values for these variables are pulled from the input arguments (from the "submit" file).
layout_number=$(printf %3s $SLURM_ARRAY_TASK_ID | tr ' ' 0)
nturbines=$1
boundary_input_arg=$2
boundary_radius=$boundary_input_arg
ndirs=$(printf %3s $3 | tr ' ' 0)
nspeeds=$(printf %2s $4 | tr ' ' 0)

# These variables stay constant for each optimization.
windrose=HornsRevWindRose
turbine_type=VestasV80_2MW
wake_model=GaussYawVariableSpread
opt_algorithm=SnoptWECAlgorithm
opt_algorithm_arg="1e-6, [3.0, 2.6, 2.2, 1.8, 1.4, 1.0, 1.0], [3e-3, 3e-3, 1e-3, 1e-4, 1e-4, 1e-5, 1e-6], [false, false, false, false, false, false, true], Int(1e5), true"
boundary_shape=CircleBoundary

# These are the file paths for the input and output info.
initial_layout_path="../data/initial-layouts/circle/${nturbines}turb/${boundary_radius}r/initial-layout-${layout_number}.txt"
final_layout_directory_path="../results/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
final_layout_file_name="final-layout-${layout_number}.yaml"
opt_info_directory="../results/opt-info/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/layout-${layout_number}/"
final_layout_figure_directory_path="../results/figures/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
final_layout_figure_file_name="final-layout-${layout_number}.png"
parallel_processing=true

# Now, we run the optimization.
julia run_opt.jl \
$ndirs \
$nspeeds \
$windrose \
$turbine_type \
$wake_model \
$opt_algorithm \
"$opt_algorithm_arg" \
$boundary_shape \
$boundary_input_arg \
$initial_layout_path \
$final_layout_directory_path \
$final_layout_file_name \
$opt_info_directory \
$final_layout_figure_directory_path \
$final_layout_figure_file_name \
$parallel_processing