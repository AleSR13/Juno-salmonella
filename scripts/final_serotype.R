##Script to generate a csv file with the combined results of SeqSero2 and MOST

#Load necessary packages
library(readr)
library(tidyr)
library(dplyr)
library(stringr)
library(xml2)
library(purrr)

## Load samples
arguments <- commandArgs(trailingOnly = TRUE)
#arguments <- paste("/data/BioGrid/hernanda/salmonella_pipeline/output/1091701622_S34_L001_serotype/", c("SeqSero_result.tsv", "1091701622_S34_L001.fastq_MLST_result.csv"), sep = "")

###########################################################################################
######################################## Functions ########################################
###########################################################################################

#Function to extract info from SeqSero2 results
extract_from_seqsero <- function(path_to_file){
  stopifnot(typeof(path_to_file)=="character")
  res_seqsero <- read_tsv(path_to_file)
  subspecies <- res_seqsero$`Predicted subspecies`
  antigen <- res_seqsero$`Predicted antigenic profile`
  prediction_seqsero <- res_seqsero$`Predicted serotype`
  contaminated_serotype <- res_seqsero$`Potential inter-serotype contamination`
  extra_info <- res_seqsero$Note
  if(length(extra_info)==0){
    extra_info <- NA
  }
  results_seqsero <- c(subspecies, antigen, prediction_seqsero, contaminated_serotype, extra_info)
  results_seqsero
}

#Function to extract info from SeqSero2 results
extract_from_xml_most <- function(path_to_file){
  stopifnot(typeof(path_to_file)=="character")
  res_most <- read_xml(path_to_file) %>% xml_find_all("//results") %>% 
    xml_children %>% as_list
  ST <- attributes(res_most[[1]])$value
  prediction_most <- map(res_most[[1]], attributes) %>% unlist %>%
    .[grep("predicted_serotype", .)+1] %>%
    str_extract("[:alnum:]+ \\([:alnum:]+\\)")
  summary[5:6,4] <- c(ST, prediction_most)
}

#Function to create summary of results
create_summary <- function(argument1){
  stopifnot(typeof(argument1)=="character")
  stopifnot(length(argument1)==1)
  #Get sample name
  sample_name <- argument1 %>% str_extract("[:alnum:]+(_[:alnum:]+)*_serotype") %>% str_remove("_serotype")
  #Extract info SeqSero2
  res_seqsero <- extract_from_seqsero(argument1)
  #Create summary of the results
  summary <- tibble("Sample"=rep(sample_name,7),
                    "Algorithm" = c(rep("SeqSero2", 5), rep("7 locus-MLST (MOST)",2)),
                    "Type" = c("Subspecies", "Antigenic profile", "Serotype", "Multiple serotypes", "Extra info", "ST_mlst", "Serotype_mlst"),
                    "Prediction" = c(res_seqsero, "Not calculated", "Not calculated"))
  summary
}

#Modify summary if MOST was run
add_most_results <- function(argument2){
  #Check if it was run or not
  res_most_csv <- read_csv(argument2)
  if(nrow(res_most_csv)>1){
    #If MOST was run, add the results to the summary table
    xml_most_res <- list.files(output_dir, pattern = "results.xml", full.names = TRUE)
    res_most <- read_xml(xml_most_res) %>% xml_find_all("//results") %>% xml_children %>% as_list
    ST <- attributes(res_most[[1]])$value
    prediction_most <- map(res_most[[1]], attributes) %>% unlist %>%
      .[grep("predicted_serotype", .)+1] %>%
      str_extract("([:alnum:]* )*[:alnum:]+") #\\([:alnum:]+\\)")
    summary[6:7,4] <- c(ST, prediction_most)
  }
  summary
}

###########################################################################################
######################################## Analysis  ########################################
###########################################################################################

# test if there is at least one argument: if not, return an error
if (length(arguments)!=2) {
  stop("Not enough arguments. The name of the files containing results from SeqSero (tsv) and MOST (csv) should be supplied", call.=FALSE)
} else {
  #Get name of output directory
  output_dir <- str_remove(arguments[1], "SeqSero_result.tsv")
  #Make summary using SeqSero2 results
  summary <- create_summary(arguments[1])
  #Get results from MLST serotyping if applicable
  summary <- add_most_results(arguments[2])
  #Save results
  write_csv(summary, paste(output_dir, "final_serotype.csv", sep = "/"))
}
