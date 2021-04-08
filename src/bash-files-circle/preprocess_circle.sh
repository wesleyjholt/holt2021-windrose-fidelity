#!/bin/sh

#######################################################################################
# THIS FILE RUNS THE PREPROCESSING STEPS FOR THE WIND FARM OPTIMIZATION STUDY
#######################################################################################

# which wind roses to create
windrose=NantucketWindRose
ndirs_vec=(25 35)
nspeeds_vec=(1)

# quantity and type of initial layouts to create
boundary_type=CircleBoundary
boundary_radius_vec=(450 600 900 1200 1500)
nturbines=9
rotor_diameter=126.4
layout_number_start=106
layout_number_end=110

# create wind rose files
for ndirs in ${ndirs_vec[@]}
do
    for nspeeds in ${nspeeds_vec[@]}
    do
        julia generate_windrose.jl $windrose $ndirs $nspeeds
    done
done

# create initial layout files
for boundary_radius in ${boundary_radius_vec[@]}
do
    layout_directory_path="../data/initial-layouts/circle/${nturbines}turb/${boundary_radius}r/"
    julia generate_initial_layout.jl $boundary_type $boundary_radius $nturbines $rotor_diameter $layout_number_start $layout_number_end $layout_directory_path
done