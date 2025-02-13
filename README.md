# Launching array job on a `slurm` HPC cluster

Consider the task of conducting a simulation study that involves generating a stochastic process and applying an estimation procedure. In this setup, you want to vary a specific parameter in the data-generating process and aim to save the estimated parameters of the underlying process for each simulation for each setting.

One can efficiently parallelize such a simulation study using `array` jobs in a `slurm` cluster. [The Slurm Workload Manager](https://slurm.schedmd.com/documentation.html) , formerly known as Simple Linux Utility for Resource Management, or simply `slurm`, is a free and open-source job scheduler for Linux and Unix-like kernels, used by many of the world's supercomputers and computer clusters. 

# A note on High Performance Computing and parallelism at the University of Geneva
You can find an introduction to High Performance Computing (HPC) and a HPC Hello World [here](https://blog-dal.netlify.app/posts/baobab_hello_world/) as well as an introduction to parallel computing on `baobab` [here](https://blog-dal.netlify.app/posts/baobab_para/), on the [Data Analytics Lab's blog page](https://blog-dal.netlify.app/). Also find the various ressources:

- [HPC User Documentation](https://doc.eresearch.unige.ch/hpc/start)
- [Setting up `R` packages on `yggdrasil`, `baobab` or `bamboo` ](https://doc.eresearch.unige.ch/hpc/applications_and_libraries#r_project_and_rstudio)
- [Web app to generate `.sh` scripts to launch job in `yggdrasil`, `baobab` or `bamboo`](https://data-analytics-lab.shinyapps.io/golembash/) and its corresponding [Github repo](https://github.com/SMAC-Group/hpc_util) 

# Notes
- This demo is assuming that the user is aiming to parallelize the execution of simulation study using `R`.
- This demo is assuming that the user is having access to a `slurm` cluster
- All commands are assumed to be performed on a linux command line that have `slurm` installed.

# Creating file tree

Locate your `$HOME` directory with:

```bash
echo $HOME
```

Create the following file tree in the `$HOME` directory.

```
├── demo_array_job_slurm
│   ├── data_temp
│   ├── report
│   ├── outfile
```

### `bash` commands

```bash
mkdir demo_array_job_slurm
cd my_simu
mkdir data_temp
mkdir report
mkdir outfile
cd ..
```

# The simulation

We consider the simulation study of generating samples of $X_i$ where $X\sim \mathcal{N}(\mu,\sigma^2)$ and computing the Maximum Likelihood Estimator of the mean:

$$\hat{\mu} = \bar{x}=\frac{1}{n} \sum_{1=i}^n X_i$$ 


and of the variance

$$\hat{\sigma}^2=\frac{1}{n-1} \sum_{1=i}^n (X_i-\bar{x})^2$$

where we vary the sample size `n`.


## `.R` file

Create and save this file as  `demo_array_job_slurm/my_simu.R`

```R
# clean ws
rm(list=ls())

# get environment variable
n = as.numeric(Sys.getenv("n"))

# set param
mean = 10
sd = 2

# get array job id environment variable
id_slurm <- as.numeric(Sys.getenv("SLURM_ARRAY_TASK_ID"))

# set seed
set.seed(123 + id_slurm)

# generate data
data = rnorm(n = n, mean=mean, sd = sd)
xbar = mean(data)
sd_hat = sd(data)

# create df
df_to_save = data.frame(matrix(NA, ncol=6))
colnames(df_to_save) = c("id_slurm","n","mu", "sd", "xbar", "sd_hat" )

# save in df
df_to_save[1,1] = id_slurm
df_to_save[1,2] = n
df_to_save[1,3] = mean
df_to_save[1,4] = sd
df_to_save[1,5] = xbar
df_to_save[1,6] = sd_hat

# save file for each simu
file_name = paste0("demo_array_job_slurm/data_temp/", "results_my_simu_",id_slurm ,"_",n, ".rda")
print(file_name)
save(df_to_save, file = file_name)

# clean after simu
rm(list=ls())
```

## `BATCH` script to launch each simulation

Create and save the `BATCH`  file that will launch your `R` script as `demo_array_job_slurm/launch_demo_array_job_slurm.sh`

```bash
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
```

Note that the flags `--no-save` and `--no-restore` are used to prevent errors such as:

```
In load(name, envir = .GlobalEnv) :
  cannot open compressed file '.RData', probable reason 'No such file or directory'
```

# `bash` file to launch all settings

We then create the file `demo_array_job_slurm/launch_all_demo_array_job_slurm.sh` to launch all three settings with different `n`.

```bash
#!/bin/sh
for n in  100 200 500
  do
  eval "export n=$n"
  sbatch --array=1-50 demo_array_job_slurm/launch_demo_array_job_slurm.sh
  done
```

Then, make this file executable with:

```
chmod u+x demo_array_job_slurm/launch_all_demo_array_job_slurm.sh 
``` 


# The recombination script

The recombination script allows to recombine all results.

## `.R` file

Create and save this file as `demo_array_job_slurm/recombine.R`

```R
# define path
folder = "demo_array_job_slurm/"
path = paste0(folder, "data_temp")

# list files
all_files = list.files(path = path)

# load first file
load(paste0(path, "/", all_files[1]))
ncol_file = ncol(df_to_save)

# create df to save
df_all_results = data.frame(matrix(NA, ncol=ncol_file))
colnames(df_all_results) = colnames(df_to_save)

# for all files load and bind
for(file_index in seq_along(all_files)){
  file_i = all_files[file_index]
  file_name = paste0(path,"/",file_i)
  load(file_name)
  df_all_results = rbind(df_all_results, df_to_save)

}

colnames(df_all_results) = colnames(df_to_save)
df_all_results = df_all_results[-1,]


# save matrix of results
time = Sys.time()
time_2 = gsub(" ", "_", time)
time_3 = gsub(":", "-", time_2)
file_name_to_save = paste0(paste0(folder, paste("df_results_demo_array_job_slurm_", time_3, sep="_"),
                                  ".rda"))
print(file_name_to_save)
save(df_all_results, file=file_name_to_save)
```

## `BATCH` script for launching the recombine `R` script

Create and save this file as `demo_array_job_slurm/launch_recombine.sh`

```bash
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

```

# Launching the simulation and recombination script

Make sure to have the following file tree before launching the simulation:

```
demo_array_job_slurm/
├── data_temp
├── launch_all_demo_array_job_slurm.sh
├── launch_demo_array_job_slurm.sh
├── launch_recombine.sh
├── my_simu.R
├── outfile
├── recombine.R
└── report
```

Make sure you are root and launch the array job with

```bash
./demo_array_job_slurm/launch_all_demo_array_job_slurm.sh 
```

`slurm` will then returns something like:


```out
Submitted batch job 37936807
Submitted batch job 37936808
Submitted batch job 37936809
```

You can check if the array task is launched with:


```bash
squeue -u username
```

Once all simulations are run, you then submit the recombination `R` script with:

```bash
sbatch demo_array_job_slurm/launch_recombine.sh
```


You should now have a file like:

```
df_results_demo_array_job_slurm__2025-02-13_18-13-31.rda
``` 

in the folder `demo_array_job_slurm`.


Well done! :nerd_face: :sunglasses:
