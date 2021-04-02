#!/bin/sh

#######################################################################################
# THIS FILE RUNS BATCHES OF OPTIMIZATIONS FOR MANY DIFFERENT TYPES OF CIRCULAR FARMS.
#######################################################################################

# This file assumes that user is running it from the "src" directory.

# set variable values
nturbine_vec=(9)
boundary_radius_vec=(900)
ndirs_vec=(30)
nspeeds_vec=(1)

# run optimizations for each combination of variables
for nturbines in ${nturbine_vec[@]}
do
    for boundary_radius in ${boundary_radius_vec[@]}
    do
        for ndirs in ${ndirs_vec[@]}
        do
            for nspeeds in ${nspeeds_vec[@]}
            do
                bash bash-files-circle/run_opt_local_circle.sh $nturbines $boundary_radius $ndirs $nspeeds
                sleep 5
            done
        done
    done
done