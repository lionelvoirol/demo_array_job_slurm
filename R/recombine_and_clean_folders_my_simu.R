# recombine all array jobs
all_files = list.files(path = "my_simu/data_temp")
mat_result_simulation = matrix(ncol=2)
for(file_i in all_files){
  file_name = paste0("my_simu/data_temp/",file_i)
  load(file_name)
  mat_result_simulation = rbind(mat_result_simulation, result_simulation_lmm)
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
                     ".rda")
  write.table(x = not_found_file, file = file_name, sep="\t")
}

# check which files were not computed and save
check_which_file_computed(directory="my_simu/data_temp", 
                          range=1:1000, file_name = "my_simu_id")

# delete all rda file and all outfile
unlink("my_simu/data_temp/*", recursive = T, force = T)
unlink("my_simu/outfile/*", recursive = T, force = T)