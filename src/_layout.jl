struct LayoutParamSet{}
    turbine_x
    turbine_y
    base_heights
end

function layout_set(initial_layout_path)
    turbine_locations = readdlm(initial_layout_path, skipstart=1)
    turbine_x = turbine_locations[:,1]
    turbine_y = turbine_locations[:,2]
    base_heights = zeros(length(turbine_x))
    layout_param = LayoutParamSet(turbine_x, turbine_y, base_heights)
    return layout_param
end