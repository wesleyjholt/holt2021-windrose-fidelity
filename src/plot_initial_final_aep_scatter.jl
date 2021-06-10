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
_initial_aeps_directory_path = ARGS[6]
_final_aeps_directory_partial_path = ARGS[7]
_initial_aeps_file_name = ARGS[8]
_final_aeps_file_name = ARGS[9]
_aeps_plot_directory_path = ARGS[10]
_nturbines = ARGS[11]
_boundary_radius = ARGS[12]


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

# get max AEP
max_aeps_data = YAML.load_file("../results/final-aeps/circle/max_aeps_circle.yaml")
max_aep = max_aeps_data["farm"]["$(_nturbines)turb"]["$(_boundary_radius)r"]["maxAEP"]


#################################################################################
# CREATE MONTE CARLO PLOTS
#################################################################################

# create necessary directories to hold plot files
mkpath(_aeps_plot_directory_path)

for i = 1:n_ndirs_vec
    for j = 1:n_nspeeds_vec
        plot_initial_final_aep_scatter(initial_aep_file_names[i,j], final_aep_file_names[i,j], max_aep, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="initial_final_aep_$(_ndirs_vec[i])dirs_$(_nspeeds_vec[j])speeds.png")
    end
end


# plot_initial_final_aep_scatter("../results/final-aeps/circle/16turb/1350r/HornsRevWindRose/VestasV80_2MW/GaussYawVariableSpread/SnoptWECAlgorithm/020dirs/01speeds/montecarlo-final-aeps-GaussYawVariableSpread.txt", "../results/final-aeps/circle/16turb/1350r/HornsRevWindRose/VestasV80_2MW/GaussYawVariableSpread/SnoptWECAlgorithm/020dirs/20speeds/montecarlo-final-aeps-GaussYawVariableSpread.txt", 143065028172.84418, save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="_initial_final_aep_.png")
# plot_initial_final_aep_scatter_categorical("../results/final-aeps/circle/16turb/1350r/HornsRevWindRose/VestasV80_2MW/GaussYawVariableSpread/SnoptWECAlgorithm/020dirs/01speeds/montecarlo-final-aeps-GaussYawVariableSpread.txt", "../results/final-aeps/circle/16turb/1350r/HornsRevWindRose/VestasV80_2MW/GaussYawVariableSpread/SnoptWECAlgorithm/020dirs/20speeds/montecarlo-final-aeps-GaussYawVariableSpread.txt", save_fig=true, path_to_fig_directory=_aeps_plot_directory_path, fig_file_name="_initial_final_aep_categorical_.png")
