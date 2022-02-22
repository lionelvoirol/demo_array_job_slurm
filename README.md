# Launching array job on a slurm HPC cluster

Consider the task of launching a simulation study that repeats `n_simu` times a simulation that include a stochastic process and that save a given vector of results `theta`. One can efficiently parallelize such a simulation study using array jobs in a slurm cluster. [The Slurm Workload Manager](https://slurm.schedmd.com/documentation.html) , formerly known as Simple Linux Utility for Resource Management, or simply Slurm, is a free and open-source job scheduler for Linux and Unix-like kernels, used by many of the world's supercomputers and computer clusters. 

# Notes

- This tutorial is assuming that the user have a University of Geneva email adress.
- All commands are assumed to be performed on a linux command line that have `slurm` installed.

# Creating file tree

We create the following file tree in the `$HOME` directory.

```
├── my_simu
│   ├── data_temp
│   ├── report
│   ├── outfile
```

### `bash` commands

```bash
mkdir my_simu
cd my_simu
mkdir data_temp
mkdir report
mkdir outfile
```

# The simulation

We consider the simulation study of generating `n_simu` of a sample of size `sample_size` of $X_i$ where $X \sim \mathcal{N}(0,1)$ and computing the mle estimator of the mean and its standard deviation (using Bessel's bias correction).


## Organising simulation by array

Consider that you want to run `n_simu` simulations using `n_array` arrays. You create the matrix of simulation seeds with:

```R
n_simu <- 10000
n_array <- 1000
ind_mat <- matrix(1:n_simu, nr = n_array, byr = T)
```

## `.R` file

Save this file in your home directory as `my_simu.R`

```R
# define number of simulations and arrays
n_simu <- 10000
n_array <- 1000

# create matrix of indices
ind_mat <- matrix(1:n_simu, nr = n_array, byr = T)

# get slurm array id and convert to numeric
id_slurm <- Sys.getenv("SLURM_ARRAY_TASK_ID")
id_slurm <- as.numeric(id_slurm)

# define id of simu to be run on array
id_simu <- ind_mat[id_slurm, ]

# meta parameters
sample_size = 1000
verbose=T

# define matrix of results
mat_results = matrix(NA, ncol = 2, nrow=length(id_simu))

for(i in id_simu){
  set.seed(i)
  sample = rnorm(n = sample_size)
  # compute theta
  theta = c(mean(sample),
            sd(sample))
  # save in matrix
  mat_results[i, ] = theta
  if(verbose & i%%2 == 0){
    print(i)
  }
}

# define file name
name_file <- paste0("my_simu/data_temp/", "mat_results", "_id_", id_slurm, ".rda")
print(name_file)

# save
save(name_file, file=name_file)
```

## `.sh` file

We define the file that will launch `my_simu.R` as `launch_my_simu.sh` and save it in your `$HOME` directory. 

```bash
#!/bin/bash
#SBATCH --job-name=my_simu
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=1:00:00
#SBATCH --partition=public-cpu,public-bigmem,public-longrun-cpu,shared-cpu,shared-bigmem
#SBATCH --mail-user=surname.name@unige.ch
#SBATCH --mail-type=ALL
#SBATCH --output my_simu/outfile/outfile_%a.out
module load GCC/9.3.0 OpenMPI/4.0.3 R/4.0.0
INFILE=my_simu.R
OUTFILE=my_simu/report/report_my_simu_${SLURM_ARRAY_TASK_ID}.Rout
srun R CMD BATCH $INFILE $OUTFILE
```

# The recombination and cleaning script

## `.R` file


```R

```

## `.sh` file

```bash
#!/bin/bash
#SBATCH --job-name=recombine_my_simu
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:00
#SBATCH --partition=public-cpu,public-bigmem,public-longrun-cpu,shared-cpu,shared-bigmem
#SBATCH --mail-user=surname.name@unige.ch
#SBATCH --mail-type=ALL
#SBATCH --output my_simu/outfile/outfile_recombine.out
module load GCC/9.3.0 OpenMPI/4.0.3 R/4.0.0
INFILE=recombine_and_clean_folders.R
OUTFILE=my_simu/report/recombine_and_clean_folders.Rout
srun R CMD BATCH $INFILE $OUTFILE

```

# Launching the simulation and recombination and cleaning script

