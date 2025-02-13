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


