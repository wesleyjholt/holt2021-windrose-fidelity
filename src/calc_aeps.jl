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
_parallel_processing = parse(Bool, ARGS[12])

layout_number_vec = _layout_number_start:_layout_number_end


#################################################################################
# IMPORT PACKAGES
#################################################################################
using DelimitedFiles
using Distributed
using ClusterManagers

ntasks = parse(Int, ENV["SLURM_NTASKS"])
println("Using $ntasks processors.")
if _parallel_processing
    if ntasks > 1
        addprocs(SlurmManager(ntasks - 1))
        println("\nProcessors have been added.")
    end
    @everywhere import FlowFarm; const ff = FlowFarm
    @everywhere include.(["_aepmodel.jl", "_farm.jl", "_layout.jl", "_turbine.jl","_windrose.jl"])
else
    import FlowFarm; const ff = FlowFarm
    include.(["_aepmodel.jl", "_farm.jl", "_layout.jl", "_turbine.jl","_windrose.jl"])
end
println("Packages are imported.")


#################################################################################
# SET LAYOUT AND MODEL PARAMETERS, CALCULATE AEPS
#################################################################################
# model parameter
model_param = model_set(_wake_model, _turbine_type, _nturbines, _windrose, _ndirs, _nspeeds)

# iterate through each layout
println("\nNow calculating AEPs for final layouts $(layout_number_vec[1]) and $(layout_number_vec[end]).")
nlayouts = length(layout_number_vec)
aeps = zeros(nlayouts)
good_indices = []
nan_indices = []
for i = 1:nlayouts
    # get layout number
    layout_number = layout_number_vec[i]

    # get turbine layout
    if isfile(_layouts_directory_path * "final-layout-$(lpad(layout_number,3,"0")).yaml") 
        layouts_file_path = _layouts_directory_path * "final-layout-$(lpad(layout_number,3,"0")).yaml"
        layout_param = layout_set(layouts_file_path, file_type="yaml")

        if _parallel_processing
            @everywhere layout_param = $layout_param
            @everywhere model_param = $model_param
            @everywhere calculate_aeps_parallel = ff.calculate_aep
            # calculate AEP
            aeps[i] = calculate_aeps_parallel(layout_param.turbine_x, layout_param.turbine_y, layout_param.base_heights, model_param.turbine_design.rotor_diameter,
                            model_param.turbine_design.hub_height, model_param.turbine_op.yaw, model_param.turbine_ct_models, model_param.turbine_design.generator_efficiency, model_param.turbine_design.cut_in_speed,
                            model_param.turbine_design.cut_out_speed, model_param.turbine_design.rated_speed, model_param.turbine_design.rated_power, model_param.wind_resource_model, model_param.turbine_power_models, model_param.farm_model_with_ti,
                            rotor_sample_points_y=model_param.velocity_sampling.rotor_sample_points_y, rotor_sample_points_z=model_param.velocity_sampling.rotor_sample_points_z)
        else
            # calculate AEP
            aeps[i] = ff.calculate_aep(layout_param.turbine_x, layout_param.turbine_y, layout_param.base_heights, model_param.turbine_design.rotor_diameter,
                            model_param.turbine_design.hub_height, model_param.turbine_op.yaw, model_param.turbine_ct_models, model_param.turbine_design.generator_efficiency, model_param.turbine_design.cut_in_speed,
                            model_param.turbine_design.cut_out_speed, model_param.turbine_design.rated_speed, model_param.turbine_design.rated_power, model_param.wind_resource_model, model_param.turbine_power_models, model_param.farm_model_with_ti,
                            rotor_sample_points_y=model_param.velocity_sampling.rotor_sample_points_y, rotor_sample_points_z=model_param.velocity_sampling.rotor_sample_points_z)
        end
        append!(good_indices, i)
    else
        aeps[i] = NaN
        append!(nan_indices, i)
    end
end

#################################################################################
# GET THE MISSING LAYOUT NUMBERS
#################################################################################
good_layouts = good_indices .+ _layout_number_start .- 1
nan_layouts = nan_indices .+ _layout_number_start .- 1

println("There are $(length(nan_indices)) missing final layouts.")
if length(nan_indices) > 0
    println("Missing layout numbers are: $(nan_layouts)")
end


#################################################################################
# SAVE ALL AEP VALUES TO A TEXT FILE
#################################################################################
# create intermediate directories (if they don't already exist)
mkpath(_aeps_directory_path)

# write to text file
open(_aeps_directory_path * _aeps_file_name, "w") do io
    write(io, "# layout number, AEP\n")
    for i = 1:length(layout_number_vec)
        write(io, "$(lpad(Int(layout_number_vec[i]),3,"0"))\t$(aeps[i])\n")
    end
end


#################################################################################
# SAVE CLEANED AEP VALUES TO A TEXT FILE (NO NANs)
#################################################################################
# write to text file
open(_aeps_directory_path * "cleaned-" * _aeps_file_name, "w") do io
    write(io, "# layout number, AEP (with NaN values removed)\n")
    for i = 1:length(good_layouts)
        write(io, "$(lpad(Int(good_layouts[i]),3,"0"))\t$(aeps[good_indices][i])\n")
    end
end