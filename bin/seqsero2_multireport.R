#############################################################################################
## Name: Combining SeqSero2 results multiple samples (when not running MOST) 
## Author: Alejandra Hernandez Segura
## Date: June 24th 2020
## Notes: The script also corrects mis-prediction of S. enterica typhimurium monophasic variant


#############################################################################################
##### Input from Snakemake 
arguments <- commandArgs(trailingOnly = TRUE)
#arguments <- c("out/serotype/salmonella_serotype_multireport.csv", list.files("out/serotype/", "SeqSero_result.tsv", recursive = TRUE, full.names = TRUE))
output_file <- arguments[1]
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
    `[`(,c(1,7,9,10,11))
}


# Create multi_report
all_reports <- map(list_seqsero2_report, extract_from_seqsero)
multi_report <- bind_rows(all_reports) %>%
  # Correct S. enterica typhimurium monophasic
  mutate("Predicted serotype" = ifelse(`Predicted serotype`== "I 4,[5],12:i:-",
                                         "Typhimurium monophasic variant", `Predicted serotype`))

write_csv(multi_report, output_file)
