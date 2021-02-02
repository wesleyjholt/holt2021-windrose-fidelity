#!/bin/bash

for ndirs in 10 20 30 40 50 60 70 80 90 100 120 150 200 360
do
    sbatch run_opt_9turb.sh ${ndirs}
    sleep 10
done