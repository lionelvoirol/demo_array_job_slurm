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
