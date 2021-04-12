include("_plot.jl")
using FillArrays

#################################################################################
# GET INPUT ARGUMENTS
#################################################################################
_ndirs_vec = eval(Meta.parse(ARGS[1]))
_nspeeds_vec = eval(Meta.parse(ARGS[2]))
_analysis_wake_model = ARGS[3]
_layout_number_start = ARGS[4]
_layout_number_end = ARGS[5]
_aeps_directory_partial_path = ARGS[6]
_aeps_file_name = ARGS[7]
_aeps_plot_directory_path = ARGS[8]
_fig_title = ARGS[9]
_fig_type = ARGS[10]


#################################################################################
# CREATE PLOTS
#################################################################################
# define plot type
_fig_type = eval(Meta.parse("$_fig_type()"))

# specify the number of groups
n_ndirs_vec = length(_ndirs_vec)
n_nspeeds_vec = length(_nspeeds_vec)

# create an array of file names (that contain the pre-calculated AEP values)
aep_file_names = fill("", n_ndirs_vec, n_nspeeds_vec)
for i = 1:n_ndirs_vec
    for j = 1:n_nspeeds_vec
        aep_file_names[i,j] = _aeps_directory_partial_path * "$(lpad(_ndirs_vec[i],3,"0"))dirs/$(lpad(_nspeeds_vec[j],2,"0"))speeds/" * _aeps_file_name
    end
end

# make create necessary directories to hold plot files
mkpath(_aeps_plot_directory_path)

# # directions plot
# for j = 1:n_nspeeds_vec
#     plot_file_name_no_ext = "final-aeps-$(lpad(_nspeeds_vec[j],2,"0"))speeds"
#     plot_aeps(aep_file_names[:,j], 360 ./ _ndirs_vec, _fig_type, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.pdf", title="", xlabel=L"\Delta\theta")
#     plot_aeps(aep_file_names[:,j], 360 ./ _ndirs_vec, _fig_type, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.png", title=_fig_title * "\n($(_nspeeds_vec[j]) speeds)", xlabel=L"\Delta\theta")
# end

# # speeds plot
# for i = 1:n_ndirs_vec
#     plot_file_name_no_ext = "final-aeps-$(lpad(_ndirs_vec[i],3,"0"))dirs"
#     plot_aeps(aep_file_names[i,:], Int.(_nspeeds_vec), _fig_type, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.pdf", title="", xlabel="Number of Wind Speeds")
#     plot_aeps(aep_file_names[i,:], Int.(_nspeeds_vec), _fig_type, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.png", title=_fig_title * "\n(" * L"\Delta\theta=" * "$(_ndirs_vec[i]))", xlabel="Number of Wind Speeds")
# end

# direction and speed plot
plot_aeps(aep_file_names, 360 ./ _ndirs_vec, Int.(_nspeeds_vec), SurfacePlot(), save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="final-aeps.pdf", title="", xlabel=L"\Delta\theta", ylabel="Number of Wind Speeds")
plot_aeps(aep_file_names, 360 ./ _ndirs_vec, Int.(_nspeeds_vec), SurfacePlot(), save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="final-aeps.png", title=_fig_title, xlabel=L"\Delta\theta", ylabel="Number of Wind Speeds")