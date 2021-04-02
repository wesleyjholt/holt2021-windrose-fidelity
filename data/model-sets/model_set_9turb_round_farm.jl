import FlowFarm; const ff = FlowFarm
using DelimitedFiles 

# this file is designed to be run only when called by opt_circle.jl

# import the initial layout file
turbine_locations = readdlm(data_directory * layout_directory * layout_filename, skipstart=1)
turbine_x = turbine_locations[:,1]
turbine_y = turbine_locations[:,2]

# calculate number of turbines
nturbines = length(turbine_x)

# set turbine base heights
turbine_z = zeros(nturbines)

# set turbine yaw values
turbine_yaw = zeros(nturbines)

# set turbine design parameters
rotor_diameter = zeros(nturbines) .+ 126.4 # m
hub_height = zeros(nturbines) .+ 90.0   # m
cut_in_speed = zeros(nturbines) .+ 3.0  # m/s
cut_out_speed = zeros(nturbines) .+ 25.0  # m/s
rated_speed = zeros(nturbines) .+ 11.4  # m/s
rated_power = zeros(nturbines) .+ 5.0E6  # W
generator_efficiency = zeros(nturbines) .+ 0.944

# rotor swept area sample points (sunflower pattern with n=100)
# rotor_points = readdlm("input-files/sunflower_pattern_100.txt", skipstart=1)
# rotor_points_y = rotor_points[:,1]
# rotor_points_z = rotor_points[:,2]
rotor_points_y = [0.0]
rotor_points_z = [0.0]

# set flow parameters
windrose_data = readdlm(data_directory * windrose_directory * windrose_filename, skipstart=1)
air_density = 1.225    # kg/m^3
ambient_ti = 0.108      # %
shearexponent = 0.31

winddirections = windrose_data[:,1]*pi/180          # radians
windspeeds = windrose_data[:,2]                     # m/s
windprobabilities = windrose_data[:,3]              # %
nstates = length(windspeeds)
ambient_tis = zeros(nstates) .+ ambient_ti        # %
measurementheight = zeros(nstates) .+ 80.0  # m

# initialize the wind shear model
wind_shear_model = ff.PowerLawWindShear(shearexponent)

# get sorted indecies 
sorted_turbine_index = sortperm(turbine_x)

# initialize the wind resource definition
windresource = ff.DiscretizedWindResource(winddirections, windspeeds, windprobabilities, 
    measurementheight, air_density, ambient_tis, wind_shear_model)

# get turbine data
turbinedata = readdlm(data_directory * "input-files/NREL5MWCPCT.txt", skipstart=2)
velpoints = turbinedata[:,1]
cppoints = turbinedata[:,2]
ctpoints = turbinedata[:,3]

# initialize power model (this is a simple power model based only on turbine design and is 
# not accurate. For examples on how to use more accurate power models, look at the example 
# optimization scripts)
power_model = ff.PowerModelCpPoints(velpoints, cppoints)
power_models = Vector{typeof(power_model)}(undef, nturbines)
for i = 1:nturbines
    power_models[i] = power_model
end

# Initialize thrust model. The user can provide a complete thrust curve. See the example 
# scripts for details on initializing them. The initialization of ct_models vector is important
# for optmization using algorithmic differentiation via the ForwardDiff.jl package.
ct_model = ff.ThrustModelCtPoints(velpoints, ctpoints)
ct_models = Vector{typeof(ct_model)}(undef, nturbines)
for i = 1:nturbines
    ct_models[i] = ct_model
end

# set up wake and related models. Here we will use the default values provided in FlowFarm.
# However, it is important to use the correct model parameters. More information and references
# are provided in the doc strings attached to each model.

# the wake deficit model predicts the impact of wind turbines wake on the wind speed
wakedeficitmodel = ff.GaussYawVariableSpread()

# the wake deflection model predicts the cross-wind location of the center of a wind turbine wake
wakedeflectionmodel = ff.GaussYawDeflection()

# the wake combination model defines how the predicted deficits in each wake should be combined to predict the total deficit at a point
wakecombinationmodel = ff.LinearLocalVelocitySuperposition()

# the local turbulence intensity models can be used to estimate the local turbulence intensity at each wind turbine or point to provide
# more accurate input information to the wake and deflection models if applicable.
localtimodel = ff.LocalTIModelNoLocalTI()

# initialize model set. This is just a convenience container for the analysis models.
model_set = ff.WindFarmModelSet(wakedeficitmodel, wakedeflectionmodel, wakecombinationmodel, localtimodel)