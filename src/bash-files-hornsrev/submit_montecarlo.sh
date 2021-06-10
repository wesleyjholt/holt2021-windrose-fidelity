#!/bin/sh

#############################################################################################
# THIS FILE RUNS BATCHES OF OPTIMIZATIONS FOR DIFFERENT PARAMETERS FOR THE HORNS REV 1 FARM.
#############################################################################################

# This file assumes that user is running it from the "src" directory.

# set variable values
nturbines=80
boundary_file_path="../data/input-files/horns-rev-boundary.txt"
ndirs_vec=(12 360)
nspeeds_vec=(1 25)
ntasksmax=250

# run optimizations for each combination of variables
for ndirs in ${ndirs_vec[@]}
do
    for nspeeds in ${nspeeds_vec[@]}
    do
        ntasksdefault=$(expr $ndirs \* $nspeeds / 10)
        _ntasks=$(($ntasksdefault<$ntasksmax ? $ntasksdefault : $ntasksmax))
        _ntasks=$(($_ntasks>1 ? $_ntasks : 1))
        echo "Now submitting jobs for $ndirs directions and $nspeeds speeds, using $_ntasks CPUs."
        sbatch --ntasks=$_ntasks bash-files-hornsrev/run_opt_slurm.sh $nturbines $boundary_file_path $ndirs $nspeeds
        sleep 3
    done
done