#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=4096M  # memory per CPU core
#SBATCH --time=01:20:00 # walltime
#SBATCH -J 'Wind Rose Study. 9 turbs. alg: snopt.'
#SBATCH --mail-user=wesleyjholt@gmail.com   # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --array=1-20    # job array number corresponds to the layout numbers
# #SBATCH --qos=test

ndirs=$1
layout_number=${SLURM_ARRAY_TASK_ID}
echo "Optimizing layout ${layout_number} with ${ndirs} directions."

module load julia/1.4
cd ".."
# change the julia filename(s) below based on what farm boundary to use
julia opt_9turb_circle.jl ${ndirs} ${layout_number}