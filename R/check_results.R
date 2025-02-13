# clean ws
rm(list = ls())

# load pkg
library(dplyr)

# load results simu
load("results/df_results_demo_array_job_slurm__2025-02-13_18-13-31.rda")

# sort
df_all_results <- df_all_results %>% arrange(n, id_slurm)
unique(df_all_results$n)

# check results
df_100 <- df_all_results %>% filter(n == 100)
df_200 <- df_all_results %>% filter(n == 200)
df_500 <- df_all_results %>% filter(n == 500)
boxplot(df_100$xbar, df_200$xbar, df_500$xbar)
abline(h=unique(df_all_results$mu))
boxplot(df_100$sd_hat, df_200$sd_hat, df_500$sd_hat)
abline(h = unique(df_all_results$sd))
