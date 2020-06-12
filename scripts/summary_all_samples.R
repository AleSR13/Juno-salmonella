##Script to generate a csv file with the combined results of SeqSero2 and MOST

#Load necessary packages
library(readr)
library(tidyr)
library(dplyr)
library(purrr)
library(stringr)

## Load samples
results_files <- commandArgs(trailingOnly = TRUE)
#results_files <- list.files("/data/BioGrid/hernandez/salmonellaserotyper/output/", pattern = "final_serotype.csv", recursive = TRUE, full.names = TRUE) 

############################## Functions ##################################################
name_subspecies <- function(subspecies_vector){
  all_names <- vector(mode = "character", length = length(subspecies_vector))
  for(i in seq_along(subspecies_vector)){
    if(subspecies_vector[i]=="I"){
      all_names[i] <- "S. enterica subsp. enterica"
    } else if(subspecies_vector[i]=="II"){
      all_names[i] <- "S. enterica subsp. salamae"
    } else if(subspecies_vector[i]=="IIIa"){
      all_names[i] <- "S. enterica subsp. arizonae"
    } else if(subspecies_vector[i]=="IIIb"){
      all_names[i] <- "S. enterica subsp. diarizonae"
    } else if(subspecies_vector[i]=="IV"){
      all_names[i] <- "S. enterica subsp. houtenae"
    } else if(subspecies_vector[i]=="VI"){
      all_names[i] <- "S. enterica subsp. indica"
    } else if(subspecies_vector[i]=="V" | subspecies_vector[i]=="bongori"){
      all_names[i] <- "S. bongori"
    }
  }
  all_names
}

############################## Functions ##################################################


# test if there is at least one argument: if not, return an error

if (length(results_files)<1) {
  stop("Missing arguments! Please provide the file (with full path) to the results of serotyping per sample", call.=FALSE)
} else {
  output_dir <- str_remove(results_files[1], "[_[:alnum:]]*_serotype/final_serotype.csv")
  all_results_files <- map(results_files, read_csv, col_types = cols("c", "c", "c", "c"))
  names(all_results_files) <- str_remove(results_files, output_dir) %>% 
    str_extract("[:alnum:]*[_[:alnum:]]*_serotype") %>%
    str_remove("_serotype")
  results_all_samples <- bind_rows(all_results_files)
  final_results <- results_all_samples[,-2] %>%
    spread(key = Type, value = Prediction) %>%
    mutate("Subspecies name" = name_subspecies(Subspecies))
  
  report <- final_results["Sample"] %>%
    mutate("Species/subspecies" = name_subspecies(final_results$Subspecies)) %>%
    mutate("Serotype" = final_results$Serotype)
  
  nonpredicted <- final_results$Subspecies == "I" &
    final_results$Serotype_mlst != "Not calculated" & 
    final_results$Serotype_mlst != "no ST" &
    final_results$Serotype_mlst != "Unnamed"
    
  report$Serotype[nonpredicted] <- final_results$Serotype_mlst[nonpredicted]
  
  write_csv(final_results, paste(output_dir, "serotype_all_samples.csv", sep = "/"))
  write_csv(report, paste(output_dir, "serotype_report.csv", sep = "/"))
}
