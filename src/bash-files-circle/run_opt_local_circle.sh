#!/bin/sh

#######################################################################################
# THIS FILE RUNS A SINGLE OPTIMIZATION FOR THE SPECIFIED LAYOUT AND SET OF PARAMETERS.
#######################################################################################

# The layout number goes here.
SLURM_ARRAY_TASK_ID=98

# The values for these variables are pulled from the input arguments (from the "submit" file).
layout_number=$(printf %3s $SLURM_ARRAY_TASK_ID | tr ' ' 0)
nturbines=$1
boundary_input_arg=$2
boundary_radius=$boundary_input_arg
ndirs=$(printf %3s $3 | tr ' ' 0)
nspeeds=$(printf %2s $4 | tr ' ' 0)

# These variables stay constant for each optimization.
wake_model=GaussYawVariableSpread
turbine_type=VestasV80_2MW
windrose=NantucketWindRose
opt_algorithm=SnoptWECAlgorithm
boundary_shape=CircleBoundary

# These are the file paths for the input and output info.
initial_layout_path="../data/initial-layouts/circle/${nturbines}turb/${boundary_radius}r/initial-layout-${layout_number}.txt"
final_layout_path="../results/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/final-layout-${layout_number}.yaml"
opt_info_directory="../results/opt-info/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/layout-${layout_number}/"
final_layout_figure_path="../results/figures/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/final-layout-${layout_number}"

# Now, we run the optimization.
julia opt.jl $ndirs $nspeeds $wake_model $turbine_type $windrose $opt_algorithm $boundary_shape $boundary_input_arg $initial_layout_path $final_layout_path $opt_info_directory $final_layout_figure_path