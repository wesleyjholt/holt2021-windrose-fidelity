include("_plot.jl")
using FillArrays
using YAML

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
_nturbines = ARGS[11]
_boundary_radius = ARGS[12]

#################################################################################
# GET AEP VALUES
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

# get max AEP
max_aeps_data = YAML.load_file("../results/final-aeps/circle/max_aeps_circle.yaml")
max_aep = max_aeps_data["farm"]["$(_nturbines)turb"]["$(_boundary_radius)r"]["maxAEP"]

#################################################################################
# CREATE PLOTS
#################################################################################
println(_aeps_directory_partial_path)

# speeds plot
for i = 1:n_ndirs_vec
    println(_ndirs_vec[i])
    plot_file_name_no_ext = "final-aeps-$(lpad(_ndirs_vec[i],3,"0"))dirs"
    plot_aeps(aep_file_names[i,:], 25 ./ _nspeeds_vec, _fig_type, max_aep=max_aep, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.pdf", _title="", _xlabel=L"\Delta v" * " (m/s)")
    plot_aeps(aep_file_names[i,:], 25 ./ _nspeeds_vec, _fig_type, max_aep=max_aep, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.png", _title=_fig_title * "\n(" * L"\Delta\theta=" * "$(round(360/_ndirs_vec[i],digits=1)) degrees)", _xlabel=L"\Delta v" * " (m/s)")
end

# directions plot
for j = 1:n_nspeeds_vec
    plot_file_name_no_ext = "final-aeps-$(lpad(_nspeeds_vec[j],2,"0"))speeds"
    plot_aeps(aep_file_names[:,j], 360 ./ _ndirs_vec, _fig_type, max_aep=max_aep, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.pdf", _title="", _xlabel=L"\Delta\theta" * " (degrees)")
    plot_aeps(aep_file_names[:,j], 360 ./ _ndirs_vec, _fig_type, max_aep=max_aep, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.png", _title=_fig_title * "\n(" * L"\Delta v" * "$(round(25/_nspeeds_vec[j],digits=1)) m/s)", _xlabel=L"\Delta\theta" * " (degrees)")
    # plot_file_name_no_ext = "final-aeps-$(lpad(_nspeeds_vec[j],2,"0"))speeds"
    # plot_aeps(aep_file_names[:,j], 360 ./ _ndirs_vec, _fig_type, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.pdf", _title="", _xlabel=L"\Delta\theta" * " (degrees)", upper_10percent=true)
    # plot_aeps(aep_file_names[:,j], 360 ./ _ndirs_vec, _fig_type, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="$plot_file_name_no_ext.png", _title=_fig_title * "\n(" * L"\Delta v" * "$(round(25/_nspeeds_vec[j],digits=1)) m/s)", _xlabel=L"\Delta\theta" * " (degrees)", upper_10percent=true)
end

# direction and speed plot
# plot_aeps(aep_file_names, 360 ./ _ndirs_vec, 25 ./ _nspeeds_vec, SurfacePlot(), save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="final-aeps.pdf", title="", xlabel=L"\Delta\theta \textrm{ (degrees)}", ylabel=L"\Delta v \textrm{ (m/s)}", upper_10percent=true)
# plot_aeps(aep_file_names, 360 ./ _ndirs_vec, 25 ./ _nspeeds_vec, SurfacePlot(), save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="final-aeps.png", title=_fig_title, xlabel=L"\Delta\theta \textrm{ (degrees)}", ylabel=L"\Delta v \textrm{ (m/s})", upper_10percent=true)