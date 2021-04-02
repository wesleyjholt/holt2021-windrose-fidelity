abstract type WindRose end


"""
    NantucketWindRose(ndirs)

Container holding parameters for the Nantucket wind rose

# Arguments
- `ndirs::Float64`: number of wind direction bins
"""
struct NantucketWindRose{I, F} <: WindRose
    ndirs::I
    nspeeds::I
    air_density::F
    ambient_ti::F
    shear_exponent::F
end
NantucketWindRose() = NantucketWindRose(10, 1, 1.225, 0.108, 0.31)
NantucketWindRose(ndirs, nspeeds) = NantucketWindRose(ndirs, nspeeds, 1.225, 0.108, 0.31)


"""
    HornsRevWindRose(ndirs, nspeeds)

Container holding parameters for the Horns Rev wind rose

# Arguments
- `ndirs::Float64`: number of wind direction bins
- `nspeeds::Float64`: number of wind speed bins
"""
struct HornsRevWindRose{I, F} <: WindRose
    ndirs::I
    nspeeds::I
    air_density::F
    ambient_ti::F
    shear_exponent::F
end
HornsRevWindRose() = HornsRevWindRose(10, 1, 1.225, 0.108, 0.31)
HornsRevWindRose(ndirs) = HornsRevWindRose(ndirs, 1, 1.225, 0.108, 0.31)
HornsRevWindRose(ndirs, nspeeds) = HornsRevWindRose(ndirs, nspeeds, 1.225, 0.108, 0.31)


function get_wind_resource_model(windrose::NantucketWindRose)
    # get wind directions and speeds joint pmf
    windrose_file_path = "../data/windrose-files/nantucket/nantucket-windrose-ave-speeds-" * lpad(windrose.ndirs, 3, "0") * "dirs.txt"
    windrose_data = readdlm(windrose_file_path, skipstart=1)
    wind_directions = windrose_data[:,1]*pi/180          # radians
    wind_speeds = windrose_data[:,2]                     # m/s
    wind_probabilities = windrose_data[:,3]
    
    # set remaining wind parameters
    nstates = length(wind_speeds)
    ambient_tis = zeros(nstates) .+ windrose.ambient_ti
    measurement_height = zeros(nstates) .+ 80.0

    # set FlowFarm wind resource models
    wind_shear_model = ff.PowerLawWindShear(windrose.shear_exponent)
    wind_resource = ff.DiscretizedWindResource(wind_directions, wind_speeds, wind_probabilities, measurement_height, windrose.air_density, ambient_tis, wind_shear_model)
    
    return wind_resource
end