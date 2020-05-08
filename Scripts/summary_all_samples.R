##Script to generate a csv file with the combined results of SeqSero2 and MOST

#Load necessary packages
library(readr)
library(tidyr)
library(dplyr)
library(purrr)
library(stringr)

## Load samples
results_files <- commandArgs(trailingOnly = TRUE)
#results_files <- list.files("/data/BioGrid/Hernandez/test1_salmonellaserotyper/Output/", pattern = "final_serotype.csv", recursive = TRUE, full.names = TRUE) 

# test if there is at least one argument: if not, return an error

if (length(results_files)<1) {
  stop("Missing arguments! Please provide the file (with full path) to the results of serotyping per sample", call.=FALSE)
} else {
  output_dir <- str_remove(results_files[1], "/[:alnum:]+_*[:alnum:]*_serotype/final_serotype.csv")
  all_results_files <- map(results_files, read_csv, col_types = cols("c", "c", "c", "c"))
  results_all_samples <- NULL
  for(i in 1:length(all_results_files)){
    results_all_samples <- bind_rows(results_all_samples, all_results_files[[i]])
  }
  final_results <- results_all_samples[,-2] %>%
    spread(key = Type, value = Prediction)
  
  write_csv(final_results, paste(output_dir, "serotype_all_samples.csv", sep = "/"))
}
