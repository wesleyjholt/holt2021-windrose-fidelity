#!/bin/sh

# nturbines_vec=(9 18)
# boundary_radius_vec=(450 600 900 1200 1500)
# ndirs_vec=(10 20 30 40 50 60 70 80 90 100 120 150 200 360)
# nspeeds_vec=(1)

# for nturbines in ${nturbines_vec[@]}
# do
#     for boundary_radius in ${boundary_radius_vec[@]}
#     do
#         for ndirs in ${ndirs_vec[@]}
#         do
#             for nspeeds in ${nspeeds_vec[@]}
#             do
#                 bash run_opt_circle_local.sh $nturbines $boundary_radius $ndirs $nspeeds
#                 sleep 5
#             done
#         done
#     done
# done

# This file assumes that user is running it from the "src" directory.

# set variable values
nturbines=80
boundary_file_path="../data/input-files/horns-rev-boundary.txt"
ndirs_vec=(12 360) #(12 36 72 120 360)
nspeeds_vec=(1 25) #(1 2 5 10 25)
ntasksmax=250

# run optimizations for each combination of variables
for ndirs in ${ndirs_vec[@]}
do
    for nspeeds in ${nspeeds_vec[@]}
    do
        ntasksdefault=$(expr $ndirs \* $nspeeds / 500)
        _ntasks=$(($ntasksdefault<$ntasksmax ? $ntasksdefault : $ntasksmax))
        _ntasks=$(($_ntasks>1 ? $_ntasks : 1))
        echo "Now submitting jobs for $ndirs directions and $nspeeds speeds, using $_ntasks CPUs."
        sbatch --ntasks=$_ntasks bash-files-circle/run_opt_slurm.sh $nturbines $boundary_file_path $ndirs $nspeeds
        sleep 3
    done
done