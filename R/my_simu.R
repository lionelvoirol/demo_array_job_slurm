# clean ws
rm(list=ls())

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