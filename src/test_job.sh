#SBATCH --ntasks=20
#SBATCH --mem-per-cpu=4096M  # memory per CPU core
#SBATCH --time=00:05:00 # walltime
#SBATCH -J 'Wind Rose Study, Horns Rev 1 Wind Farm'
#SBATCH --array=1-5    # job array number corresponds to the layout numbers
# #SBATCH --qos=test

module load julia/1.4
julia test_aepcalc.jl