#!/bin/bash
#SBATCH --job-name=recombine_my_simu
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --partition=public-cpu,public-bigmem,public-longrun-cpu,shared-cpu,shared-bigmem
#SBATCH --mail-user=lionel.voirol@unige.ch
#SBATCH --mail-type=ALL
#SBATCH --output my_simu/outfile/outfile_recombine.out
module load GCC/9.3.0 OpenMPI/4.0.3 R/4.0.0
INFILE=recombine_and_clean_folders_my_simu.R
OUTFILE=my_simu/report/recombine_and_clean_folders.Rout
srun R CMD BATCH $INFILE $OUTFILE