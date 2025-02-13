#!/bin/sh
for n in  100 200 500
  do
  eval "export n=$n"
  sbatch --array=1-50 demo_array_job_slurm/launch_demo_array_job_slurm.sh
  done

