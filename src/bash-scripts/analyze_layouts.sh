#!/bin/bash

# for radius in 450 600 900 1200 1500
# do
#     julia analyze_layouts_within_farm_types.jl 9 circle ${radius} snopt-wec
#     sleep 1
# done

radii=450,600,900,1200,1500
julia analyze_layouts_across_farm_types.jl 9 circle $radii snopt-wec