include.(["_plot.jl","_utilities.jl"])
using FillArrays
import YAML


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
_nturbines = ARGS[9]
_boundary_radius = ARGS[10]


#################################################################################
# GET AEP VALUES
#################################################################################
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

# get max AEP
max_aeps_data = YAML.load_file("../results/final-aeps/circle/max_aeps_circle.yaml")
max_aep = max_aeps_data["farm"]["$(_nturbines)turb"]["$(_boundary_radius)r"]["maxAEP"]


#################################################################################
# GET THE X PLOT POINTS
#################################################################################
# get array of sample sizes
# n_points = 4
# n_samples = 150
# sample_sizes = fill(zeros(0), n_ndirs_vec, n_nspeeds_vec)
# for i = 1:n_ndirs_vec
#     for j = 1:n_nspeeds_vec
#         # sample_sizes[i,j] = get_log_spaced_montecarlo_points(n_points, n_samples)
#         sample_sizes[i,j] = collect(Int.(round.(2:1.462:120))) #collect(3:2:139)
#     end
# end
# Int.(round.(2:1.462:120))
sample_sizes = fill(collect(Int.(round.(3:2.611:225))), n_ndirs_vec, n_nspeeds_vec)

# create necessary directories to hold plot files
mkpath(_aeps_plot_directory_path)


#################################################################################
# CREATE MONTE CARLO PLOTS
#################################################################################
for i = 1:n_ndirs_vec
    for j = 1:n_nspeeds_vec
        plot_montecarlo(aep_file_names[i,j], max_aep, sample_sizes[i,j], _ndirs_vec, _nspeeds_vec, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="montecarlo_$(_ndirs_vec[i])dirs_$(_nspeeds_vec[j])speeds.png")
    end
end
