# Launching array job on a slurm HPC cluster



Consider the task of launching a simulation study that repeats `n_simu` times a simulation that include a stochastic process and that save a given vector of results `theta`. One can efficiently parallelize such a simulation study using array jobs in a slurm cluster. [The Slurm Workload Manager](https://slurm.schedmd.com/documentation.html) , formerly known as Simple Linux Utility for Resource Management, or simply Slurm, is a free and open-source job scheduler for Linux and Unix-like kernels, used by many of the world's supercomputers and computer clusters. 

# Notes

- This demo is assuming that the user have a University of Geneva email adress.
- This demo is assuming that the user is using the University of Geneva's clusters `baobab` or `yggdrasil`.
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

We consider the simulation study of generating `n_simu` of a sample of size `sample_size` of ![formula](https://render.githubusercontent.com/render/math?math=\bbox[white]{X_i} ) where ![formula](https://render.githubusercontent.com/render/math?math=\bbox[white]{X\sim\mathcal{N}(0,1)} ) and computing the mle estimator of the mean and its standard deviation (using Bessel's bias correction).


## Organising simulation by array

Consider that you want to run `n_simu` simulations using `n_array` arrays. You create the matrix of simulation seeds with:

```R
# define number of simulations and arrays
n_simu <- 100000
n_array <- 100

# create matrix of indices
ind_mat <- matrix(1:n_simu, nr = n_array, byr = T)
```

## `.R` file

Save this file in your `$HOME` directory as `my_simu.R`

```R
# define number of simulations and arrays
n_simu <- 100000
n_array <- 100

# create matrix of indices
ind_mat <- matrix(1:n_simu, nr = n_array, byr = T)

# get slurm array id and convert to numeric
id_slurm <- Sys.getenv("SLURM_ARRAY_TASK_ID")
id_slurm <- as.numeric(id_slurm)

# define id of simu to be run on array
id_simu <- ind_mat[id_slurm, ]

# meta parameters
sample_size = 100000
verbose=T

# define matrix of results
mat_results = matrix(NA, ncol = 2, nrow=length(id_simu))

for(simu_index in seq(length(id_simu))){
  # get seed 
  i_seed=id_simu[simu_index]
  # set seed
  set.seed(i_seed)
  # generate data
  sample = rnorm(n = sample_size)
  # compute theta
  theta = c(mean(sample),
            sd(sample))
  # save in matrix
  mat_results[simu_index, ] = theta
  # print status if verbose
  if(verbose & simu_index %% 2 == 0){
    print(simu_index)
  }
}

# define file name
name_file <- paste0("my_simu/data_temp/", "mat_results", "_id_", id_slurm, ".rda")

# print file name
print(name_file)

# save
save(mat_results, file=name_file)
```

## `.sh` file

We define the file that will launch `my_simu.R`. Save this file in your `$HOME` directory as `launch_my_simu.sh`

```bash
#!/bin/bash
#SBATCH --job-name=my_simu
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --partition=public-cpu,public-bigmem,public-longrun-cpu,shared-cpu,shared-bigmem
#SBATCH --mail-user=lionel.voirol@unige.ch
#SBATCH --mail-type=ALL
#SBATCH --output my_simu/outfile/outfile_%a.out
module load GCC/10.2.0 OpenMPI/4.0.5 R/4.0.4
INFILE=my_simu.R
OUTFILE=my_simu/report/report_my_simu_${SLURM_ARRAY_TASK_ID}.Rout
srun R CMD BATCH $INFILE $OUTFILE
```

# The recombination and cleaning script

The recombination and cleaning script performs the followng tasks:

- recombine results from all arrays and save the complete matrix of results under `my_simu/mat_result_simulation_date_time.rda`
- check if there are some simulation for which the resulting `.rda` file is not found and store a log under `my_simu/my_simu/failed_array_date_time.txt`
- clean the `my_simu/data_temp` directory
- clean the `my_simu/outfile` directory

## `.R` file

Save this file in your `$HOME` directory as `recombine_and_clean_folders_my_simu.R`

```R
# recombine all array jobs
all_files = list.files(path = "my_simu/data_temp")
mat_result_simulation = matrix(ncol=2)
for(file_i in all_files){
  file_name = paste0("my_simu/data_temp/",file_i)
  load(file_name)
  mat_result_simulation = rbind(mat_result_simulation, mat_results)
}
mat_result_simulation = mat_result_simulation[-1,]

# print dimension of matrix of results
dim(mat_result_simulation)

# save matrix of results
time = Sys.time()
time_2 = gsub(" ", "_", time)
time_3 = gsub(":", "-", time_2)
file_name_to_save = paste0(paste("my_simu/mat_result_simulation", time_3, sep="_"),
                           ".rda")
print(file_name_to_save)
save(mat_result_simulation, file=file_name_to_save)

# define function to check which files were not computed and save
check_which_file_computed = function(directory, range, file_name, extension = ".rda"){
  all_present_file = list.files(directory)
  all_suposed_file = paste0(file_name, "_",range, extension)
  not_found_file = all_suposed_file[which(!all_suposed_file %in% all_present_file)]
  time = Sys.time()
  time_2 = gsub(" ", "_", time)
  time_3 = gsub(":", "-", time_2)
  file_name = paste0(paste("my_simu/failed_array", time_3, sep="_"),
                     ".txt")
  write.table(x = not_found_file, file = file_name, sep="\t")
}

# check which files were not computed and save
check_which_file_computed(directory="my_simu/data_temp", 
                          range=1:100, file_name = "mat_results_id")

# delete all rda file and all outfile
# unlink("my_simu/data_temp/*", recursive = T, force = T)
# unlink("my_simu/outfile/*", recursive = T, force = T)
```

## `.sh` file

Save this file in your `$HOME` directory as `launch_recombine_my_simu.sh`

```bash
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
```

# Launching the simulation and recombination and cleaning script

Launch the array job with

```bash
sbatch array=1-100 launch_my_simu.sh
```

`slurm` will then retun something like:


```out
Submitted batch job 8602501
```

You then submit the recombination and cleaning script with

```bash
sbatch --dependency=afterany:8602501 launch_recombine_my_simu.sh 
```

:warning: **make sure to change the corresponding job id.**

You can check if the array task is launched with:

```bash
squeue -u username
```

:warning: **make sure to change the corresponding username.**

You should see something like:

```out
       8602501_995 shared-cp  my_simu username  R       0:05      1 cpu117
       8602501_996 shared-cp  my_simu username  R       0:05      1 cpu117
       8602501_997 shared-cp  my_simu username  R       0:05      1 cpu117
       8602501_998 shared-cp  my_simu username  R       0:05      1 cpu117
       8602501_999 shared-cp  my_simu username  R       0:05      1 cpu117
      8602501_1000 shared-cp  my_simu username  R       0:05      1 cpu117
```

That's it! Once all arrays of the simulation are computed, the recombination and cleaning script will be launched. You will then find your results under `my_simu`. More specifically, 

- The matrix of all results under `my_simu/mat_result_simulation_date_time.rda`
- The `.Rout` for all array job under `my_simu/report`
- The list of potential array that did not computed under `my_simu/failed_array_date_time.txt`

Well done! :nerd_face: :sunglasses:
