#!/bin/sh

#SBATCH --ntasks=10
#SBATCH --mem-per-cpu=2056  # memory per CPU core
#SBATCH --time=00:05:00 # walltime
#SBATCH -J 'Wind Rose Study, Horns Rev 1 Wind Farm'
# #SBATCH -o ./Report/output.%a.out
# #SBATCH --array=1-2    # job array number corresponds to the layout numbers
# #SBATCH --qos=test

# LOAD JULIA
module load julia

# CALL AEP CALCULATOR
julia calc_aeps.jl $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12}
