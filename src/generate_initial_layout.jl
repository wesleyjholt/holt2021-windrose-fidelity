#################################################################################
# INCLUDE THE BOUNDARY SOURCE FILE
#################################################################################
include("_boundary.jl")

#################################################################################
# GET INPUT PARAMETERS
#################################################################################
_boundary_type = ARGS[1]
_boundary_input_arg = ""
try parse(Float64, ARGS[2])
    global _boundary_input_arg = parse(Float64, ARGS[2])
catch
    global _boundary_input_arg = "\"$(ARGS[2])\""
end
_nturbines = parse(Int64, ARGS[3])
_rotor_diameter = parse(Float64, ARGS[4])
_layout_number_start = parse(Int64, ARGS[5])
_layout_number_end = parse(Int64, ARGS[6])
_layout_directory_path = ARGS[7]

#################################################################################
# GENERATE INITIAL LAYOUT
#################################################################################
mkpath(_layout_directory_path)
boundary = eval(Meta.parse("$_boundary_type($_boundary_input_arg)"))
for layout_number in _layout_number_start:_layout_number_end
    layout_file_path = _layout_directory_path * "initial-layout-$(lpad(layout_number,3,"0")).txt"
    generate_random_layout(layout_file_path, _nturbines, _rotor_diameter, boundary, min_spacing=2.0)
end