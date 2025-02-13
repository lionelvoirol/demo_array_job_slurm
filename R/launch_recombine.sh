#!/bin/bash
#SBATCH --job-name=recombine
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --partition=shared-cpu,shared-bigmem,public-cpu,public-bigmem
#SBATCH --mail-user=your_email
#SBATCH --mail-type=NONE
#SBATCH --output demo_array_job_slurm/outfile/outfile_recombine.out
module load GCC/9.3.0 OpenMPI/4.0.3 R/4.0.0
INFILE=demo_array_job_slurm/recombine.R
OUTFILE=demo_array_job_slurm/report/recombine.Rout
srun R CMD BATCH $INFILE $OUTFILE
