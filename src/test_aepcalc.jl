using Distributed
using ClusterManagers

clk1 = time()
@everywhere using FlowFarm; const ff = FlowFarm
@everywhere include("model_set_7_ieacs4_reduced_wind_rose.jl")
clk2 = time()

println("Imported Flowfarm and set up models in $(round(clk2-clk1, digits=3)) seconds.")

# calculate AEP
clk1 = time()
AEP = ff.calculate_aep(turbine_x, turbine_y, turbine_z, rotor_diameter,
                    hub_height, turbine_yaw, ct_models, generator_efficiency, cut_in_speed,
                    cut_out_speed, rated_speed, rated_power, windresource, power_models, model_set,
                    rotor_sample_points_y=rotor_points_y, rotor_sample_points_z=rotor_points_z)
clk2 = time()

println("AEP = $(round(AEP, digits=5)) MWh")
println("Ran in $(round(clk2-clk1, digits=3)) seconds.")