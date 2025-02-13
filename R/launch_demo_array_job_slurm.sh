#!/bin/bash
#SBATCH --partition=shared-cpu,shared-bigmem,public-cpu,public-bigmem,public-longrun-cpu
#SBATCH --time=00-00:10:00
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mail-user=your_email
#SBATCH --job-name=demo_array_job_slurm
#SBATCH --mail-type=NONE
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null
module load GCC/9.3.0 OpenMPI/4.0.3 R/4.0.0

INFILE=demo_array_job_slurm/my_simu.R
OUTFILE=demo_array_job_slurm/report/report_${n}_${SLURM_ARRAY_TASK_ID}.Rout
OUTLOG=demo_array_job_slurm/outfile/outfile_${n}_${SLURM_ARRAY_TASK_ID}.out

exec > $OUTLOG 2>&1


srun R CMD BATCH --no-save --no-restore $INFILE $OUTFILE

