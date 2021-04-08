include("_plot.jl")
using FillArrays

#################################################################################
# GET INPUT ARGUMENTS
#################################################################################
_ndirs_vec = eval(Meta.parse(ARGS[1]))
_nspeeds_vec_directory = ""
_layout_number_start = ARGS[3]
_layout_number_end = ARGS[4]
_aeps_directory_partial_path = ARGS[5]
_aeps_file_name = ARGS[6]
_aeps_plot_directory_path = ARGS[7]
_aeps_plot_file_name = ARGS[8]
_fig_title = ARGS[9]
_fig_type = ARGS[10]

# println("_ndirs_vec = ", _ndirs_vec)
# println("_nspeeds_vec_directory = ", _nspeeds_vec_directory)
# println("_layout_number_start = ", _layout_number_start)
# println("_layout_number_end = ", _layout_number_end)
# println("_aeps_directory_partial_path = ", _aeps_directory_partial_path)
# println("_aeps_file_name = ", _aeps_file_name)
# println("_aeps_plot_directory_path = ", _aeps_plot_directory_path)
# println("_aeps_plot_file_name = ", _aeps_plot_file_name)
# println("_fig_title = ", _fig_title)
# println()

#################################################################################
# CREATE PLOTS
#################################################################################
# define plot type
_fig_type = eval(Meta.parse("$_fig_type()"))

# specify the number of groups
ngroups = length(_ndirs_vec)

# create an array of file names (that contain the pre-calculated AEP values)
aep_file_names = fill("", ngroups)
for i = 1:ngroups
    aep_file_names[i] = _aeps_directory_partial_path * "$(lpad(_ndirs_vec[i],3,"0"))dirs/$(_nspeeds_vec_directory)" * _aeps_file_name
end

# create the plot
plot_aeps(aep_file_names, 360 ./ _ndirs_vec, _fig_type, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name=_aeps_plot_file_name, title=_fig_title)
