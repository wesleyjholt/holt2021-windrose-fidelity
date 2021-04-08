#!/bin/sh

#######################################################################################
# THIS FILE RUNS THE PREPROCESSING STEPS FOR THE WIND FARM OPTIMIZATION STUDY
#######################################################################################

# which wind roses to create
windrose=HornsRevWindRose
ndirs_vec=(12 36 72 120 360)
nspeeds_vec=(1 2 5 10 25)

# quantity and type of initial layouts to create
boundary_type=FreeFormBoundary
boundary_file_path="../data/input-files/horns-rev-boundary.txt"
nturbines=80
rotor_diameter=80.0
layout_number_start=1
layout_number_end=100

# create wind rose files
for ndirs in ${ndirs_vec[@]}
do
    for nspeeds in ${nspeeds_vec[@]}
    do
        echo "Creating wind rose with $ndirs directions and $nspeeds speeds..."
        julia generate_windrose.jl $windrose $ndirs $nspeeds
    done
done

# create initial layout files
echo "Now creating initial layouts $layout_number_start through $layout_number_end"
layout_directory_path="../data/initial-layouts/horns-rev/"
julia generate_initial_layout.jl $boundary_type $boundary_file_path $nturbines $rotor_diameter $layout_number_start $layout_number_end $layout_directory_path
