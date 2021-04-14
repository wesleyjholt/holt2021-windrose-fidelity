#!/bin/sh

#######################################################################################
# THIS FILE RUNS THE PREPROCESSING STEPS FOR THE WIND FARM OPTIMIZATION STUDY
#######################################################################################

# set options
create_windroses=false
create_initial_layouts=true

# which wind roses to create
windrose=HornsRevWindRose
ndirs_vec=(360 180 120 90 72 60 51 45 36 33 30 28 26 24 22 20 18 16 14 12 10 8)
nspeeds_vec=(1 5 10 20)

# quantity and type of initial layouts to create
boundary_type=CircleBoundary
boundary_radius_vec=(900 1350)
nturbines=16
rotor_diameter=80
layout_number_start=1
layout_number_end=100

# create wind rose files
if create_windroses==true
then
    for ndirs in ${ndirs_vec[@]}
    do
        for nspeeds in ${nspeeds_vec[@]}
        do
            echo "Creating wind rose with $ndirs directions and $nspeeds speeds..."
            julia generate_windrose.jl $windrose $ndirs $nspeeds
        done
    done
fi

# create initial layout files
if create_initial_layouts==true
then
    for boundary_radius in ${boundary_radius_vec[@]}
    do
        echo "Now creating initial layouts $layout_number_start through $layout_number_end"
        layout_directory_path="../data/initial-layouts/circle/${nturbines}turb/${boundary_radius}r/"
        julia generate_initial_layout.jl \
            $boundary_type \
            $boundary_radius \
            $nturbines \
            $rotor_diameter \
            $layout_number_start \
            $layout_number_end \
            $layout_directory_path
    done
fi