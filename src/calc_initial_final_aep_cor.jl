include("_utilities.jl")
using StatsBase
using Statistics
using FillArrays
import YAML

#################################################################################
# GET INPUT ARGUMENTS
#################################################################################
_ndirs_vec = eval(Meta.parse(ARGS[1]))
_nspeeds_vec = eval(Meta.parse(ARGS[2]))
_analysis_wake_model = ARGS[3]
_layout_number_start = parse(Int64, ARGS[4])
_layout_number_end = parse(Int64, ARGS[5])
_initial_aeps_directory_path = ARGS[6]
_final_aeps_directory_partial_path = ARGS[7]
_initial_aeps_file_name = ARGS[8]
_final_aeps_file_name = ARGS[9]
_nturbines = ARGS[10]
_boundary_radius = ARGS[11]


#################################################################################
# GET AEP VALUES
#################################################################################
# specify the number of groups
n_ndirs_vec = length(_ndirs_vec)
n_nspeeds_vec = length(_nspeeds_vec)

# create an array of file names (that contain the pre-calculated AEP values)
initial_aep_file_names = fill("", n_ndirs_vec, n_nspeeds_vec)
final_aep_file_names = fill("", n_ndirs_vec, n_nspeeds_vec)
for i = 1:n_ndirs_vec
    for j = 1:n_nspeeds_vec
        initial_aep_file_names[i,j] = _initial_aeps_directory_path * _initial_aeps_file_name
        final_aep_file_names[i,j] = _final_aeps_directory_partial_path * "$(lpad(_ndirs_vec[i],3,"0"))dirs/$(lpad(_nspeeds_vec[j],2,"0"))speeds/" * _final_aeps_file_name
    end
end

# calculate correlation coefficients
for i = 1:n_ndirs_vec
    for j = 1:n_nspeeds_vec
        initial_aeps = get_aep_values_from_file_names(initial_aep_file_names[i,j])[101:4900]
        final_aeps = get_aep_values_from_file_names(final_aep_file_names[i,j])[1:4800]
        initial_final_aep_corpearson = cor(initial_aeps, final_aeps)
        initial_final_aep_corspearman = corspearman(initial_aeps, final_aeps)
        initial_final_aep_corkendall = corkendall(initial_aeps, final_aeps)
        println("\n $(_ndirs_vec[i]) directions and $(_nspeeds_vec[j]) speeds:")
        println("Pearson correlation: $initial_final_aep_corpearson")
        println("Spearman correlation: $initial_final_aep_corspearman")
        println("Kendall's Tau: $initial_final_aep_corkendall")
    end
end