#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=2048M  # memory per CPU core
#SBATCH --time=00:05:00 # walltime
#SBATCH -J 'Wind Rose Study. 9 turbs. alg: snopt.'
#SBATCH --mail-user=wesleyjholt@gmail.com   # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --array=1-10    # job array number corresponds to the layout numbers
# #SBATCH --qos=test

ndirs=$1
layout_number=${SLURM_ARRAY_TASK_ID}
echo "Optimizing layout ${layout_number} with ${ndirs} directions."

module load julia/1.4
cd ".."
julia opt_9turb.jl ${ndirs} ${layout_number}