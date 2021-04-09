#!/bin/sh

#############################################################################################
# THIS FILE RUNS BATCHES OF OPTIMIZATIONS FOR DIFFERENT PARAMETERS FOR THE HORNS REV 1 FARM.
#############################################################################################

# This file assumes that user is running it from the "src" directory.

# set variable values
nturbines=80
boundary_file_path="../data/input-files/horns-rev-boundary.txt"
ndirs_vec=(12, 36)
nspeeds_vec=(1, 2)
ntasksmax=50

# run optimizations for each combination of variables
for ndirs in ${ndirs_vec[@]}
do
    for nspeeds in ${nspeeds_vec[@]}
    do
        echo $ndirs
        echo $nspeeds
        ntasksdefault=$(expr $ndirs \* $nspeeds / 5)
        echo $ntasksdefault
        sbatch --ntasks=$(($ntasksdefault<$ntasksmax ? $ntasksdefault : $ntasksmax)) bash-files-hornsrev/run_opt_slurm.sh $nturbines $boundary_file_path $ndirs $nspeeds
        sleep 5
    done
done