#!/bin/sh

#SBATCH --mem-per-cpu=4096M  # memory per CPU core
#SBATCH --time=02:00:00 # walltime
#SBATCH -J 'Wind Rose Study, Horns Rev 1 Wind Farm'
#SBATCH -o ./Report/output.%a.out
#SBATCH --array=3-5    # job array number corresponds to the layout numbers
# #SBATCH --qos=test


# The values for these variables are pulled from the input arguments (from the "submit" file).
layout_number=$(printf %3s $SLURM_ARRAY_TASK_ID | tr ' ' 0)
nturbines=$1
boundary_input_arg=$2
ndirs=$(printf %3s $3 | tr ' ' 0)
nspeeds=$(printf %2s $4 | tr ' ' 0)

# These variables stay constant for each optimization.
windrose=NantucketWindRose
turbine_type=NREL_5MW
wake_model=GaussYawVariableSpread
opt_algorithm=SnoptWECAlgorithm
opt_algorithm_arg="1e-6, [3.0, 2.6, 2.2, 1.8, 1.4, 1.0, 1.0], [3e-3, 3e-3, 1e-3, 1e-4, 1e-4, 1e-5, 1e-6], [false, false, false, false, false, false, true], Int(1e5), false"
boundary_shape=FreeFormBoundary

# These are the file paths for the input and output info.
initial_layout_path="../data/initial-layouts/horns-rev/initial-layout-${layout_number}.txt"
final_layout_directory_path="../results/final-layouts/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
final_layout_file_name="final-layout-${layout_number}.yaml"
opt_info_directory="../results/opt-info/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/layout-${layout_number}/"
final_layout_figure_directory_path="../results/figures/final-layouts/horns-rev/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/${nspeeds}speeds/"
final_layout_figure_file_name="final-layout-${layout_number}.png"
parallel_processing=true

# Now, we run the optimization.
module load julia
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