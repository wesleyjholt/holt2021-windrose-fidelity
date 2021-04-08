#!/bin/sh

#############################################################################################
# THIS FILE RUNS BATCHES OF OPTIMIZATIONS FOR DIFFERENT PARAMETERS FOR THE HORNS REV 1 FARM.
#############################################################################################

# This file assumes that user is running it from the "src" directory.

# set variable values
nturbines=80
boundary_file_path="../data/input-files/horns-rev-boundary.txt"
ndirs_vec=(12)
nspeeds_vec=(1)

# run optimizations for each combination of variables
for ndirs in ${ndirs_vec[@]}
do
    for nspeeds in ${nspeeds_vec[@]}
    do
        sbatch bash-files-hornsrev/run_opt_slurm.sh $nturbines $boundary_file_path $ndirs $nspeeds
        sleep 5
    done
done