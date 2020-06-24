#############################################################################################
## Name: Combining SeqSero2 results multiple samples (when not running MOST) 
## Author: Alejandra Hernandez Segura
## Date: June 24th 2020
## Notes: The script also corrects mis-prediction of S. enterica typhimurium monophasic variant


#############################################################################################
##### Input from Snakemake 
arguments <- commandArgs(trailingOnly = TRUE)
#arguments <- c("/data/BioGrid/hernanda/salmonella_pipeline/output/", list.files("/data/BioGrid/hernanda/salmonella_pipeline/output/", "SeqSero_result.tsv", recursive = TRUE, full.names = TRUE))
output_dir <- arguments[1]
list_seqsero2_report <- arguments[-1]

#############################################################################################
##### Requirements
library(readr)
library(purrr)
library(stringr)
library(dplyr)

#############################################################################################
##### Generate multi report 

##  Function to filter important information from seqsero2 report
extract_from_seqsero <- function(path_to_file){
  seqsero_report <- read_delim(path_to_file, delim = "\t", col_types = "ccccccccccc") %>%
    `[`(,c(7,9,10,11))
}

# Extract sample names
sample_names <- list_seqsero2_report %>% 
  str_extract("[:alnum:]+[_[:alnum:]]*_serotype") %>%
  str_remove("_serotype")

# Create multi_report
all_reports <- map(list_seqsero2_report, extract_from_seqsero)
names(all_reports) <- sample_names
multi_report <- bind_rows(all_reports, .id = "Sample")%>%
  # Correct S. enterica typhimurium monophasic
  mutate("Predicted serotype" = ifelse(`Predicted serotype`== "I 4,[5],12:i:-",
                                         "Typhimurium monophasic variant", `Predicted serotype`))

write_csv(multi_report, paste0(output_dir, "/salmonella_multi_report.csv"))
