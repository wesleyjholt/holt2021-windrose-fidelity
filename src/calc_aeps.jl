include.(["_aepmodel.jl", "_farm.jl", "_layout.jl", "_turbine.jl","_windrose.jl"])
import FlowFarm; const ff=FlowFarm
using DelimitedFiles

#################################################################################
# GET INPUT ARGUMENTS
#################################################################################
_ndirs = parse(Int64, ARGS[1])
_nspeeds = parse(Int64, ARGS[2])
_windrose = ARGS[3]
_nturbines = parse(Int64, ARGS[4])
_turbine_type = ARGS[5]
_wake_model = ARGS[6]
_layout_number_start = parse(Int64, ARGS[7])
_layout_number_end = parse(Int64, ARGS[8])
_layouts_directory_path = ARGS[9]
_aeps_directory_path = ARGS[10]
_aeps_file_name = ARGS[11]

layout_number_vec = _layout_number_start:_layout_number_end

#################################################################################
# SET LAYOUT AND MODEL PARAMETERS, CALCULATE AEPS
#################################################################################
# model parameter
model_param = model_set(_wake_model, _turbine_type, _nturbines, _windrose, _ndirs, _nspeeds)

# iterate through each layout
nlayouts = length(layout_number_vec)
aeps = zeros(nlayouts)
for i = 1:nlayouts
    # get layout number
    layout_number = layout_number_vec[i]

    # get turbine layout
    layouts_file_path = _layouts_directory_path * "final-layout-$(lpad(layout_number,3,"0")).yaml"
    layout_param = layout_set(layouts_file_path, file_type="yaml")

    # calculate AEP
    aeps[i] = ff.calculate_aep(layout_param.turbine_x, layout_param.turbine_y, layout_param.base_heights, model_param.turbine_design.rotor_diameter,
                    model_param.turbine_design.hub_height, model_param.turbine_op.yaw, model_param.turbine_ct_models, model_param.turbine_design.generator_efficiency, model_param.turbine_design.cut_in_speed,
                    model_param.turbine_design.cut_out_speed, model_param.turbine_design.rated_speed, model_param.turbine_design.rated_power, model_param.wind_resource_model, model_param.turbine_power_models, model_param.farm_model_with_ti,
                    rotor_sample_points_y=model_param.velocity_sampling.rotor_sample_points_y, rotor_sample_points_z=model_param.velocity_sampling.rotor_sample_points_z)
end


#################################################################################
# SAVE AEP VALUES TO A TEXT FILE
#################################################################################
# create intermediate directories (if they don't already exist)
mkpath(_aeps_directory_path)

# write to text file
open(_aeps_directory_path * _aeps_file_name, "w") do io
    write(io, "# AEP values for layouts $_layout_number_start to $_layout_number_end")
    writedlm(io, aeps)
end