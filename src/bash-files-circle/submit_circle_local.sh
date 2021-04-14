#!/bin/sh

#######################################################################################
# THIS FILE RUNS BATCHES OF OPTIMIZATIONS FOR MANY DIFFERENT TYPES OF CIRCULAR FARMS.
#######################################################################################

# This file assumes that user is running it from the "src" directory.

# set variable values
nturbines_vec=(16)
boundary_radius_vec=(900)
ndirs_vec=(16)
nspeeds_vec=(5)

# run optimizations for each combination of variables
for nturbines in ${nturbines_vec[@]}
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