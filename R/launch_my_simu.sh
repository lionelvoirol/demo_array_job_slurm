#!/bin/bash
#SBATCH --job-name=my_simu
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --partition=public-cpu,public-bigmem,public-longrun-cpu,shared-cpu,shared-bigmem
#SBATCH --mail-user=lionel.voirol@unige.ch
#SBATCH --mail-type=ALL
#SBATCH --output my_simu/outfile/outfile_%a.out
module load GCC/9.3.0 OpenMPI/4.0.3 R/4.0.0
INFILE=my_simu.R
OUTFILE=my_simu/report/report_my_simu_${SLURM_ARRAY_TASK_ID}.Rout
srun R CMD BATCH $INFILE $OUTFILE
~                                            