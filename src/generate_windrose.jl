#################################################################################
# INCLUDE THE WIND ROSE SOURCE FILE
#################################################################################
include("_windrose.jl")

#################################################################################
# GET INPUT PARAMETERS
#################################################################################
_windrose = ARGS[1]
_ndirs = parse(Int64, ARGS[2])
_nspeeds = parse(Int64, ARGS[3])

#################################################################################
# DEFINE AND RESAMPLE WIND ROSE, SAVE WIND ROSE FILE TO DATA DIRECTORY
#################################################################################
windrose = eval(Meta.parse("$_windrose($_ndirs,$_nspeeds)"))
resample_wind_resource(windrose)