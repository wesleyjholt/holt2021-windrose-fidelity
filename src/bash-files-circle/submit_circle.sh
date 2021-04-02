#!/bin/sh

nturbine_vec=(9 18)
boundary_radius_vec=(450 600 900 1200 1500)
ndirs_vec=(10 20 30 40 50 60 70 80 90 100 120 150 200 360)
nspeeds_vec=(1)

for nturbines in ${nturbine_vec[@]}
do
    for boundary_radius in ${boundary_radius_vec[@]}
    do
        for ndirs in ${ndirs_vec[@]}
        do
            for nspeeds in ${nspeeds_vec[@]}
            do
                bash run_opt_circle_local.sh $nturbines $boundary_radius $ndirs $nspeeds
                sleep 5
            done
        done
    done
done
