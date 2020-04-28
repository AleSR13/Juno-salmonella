##Script to generate a csv file with the combined results of SeqSero2 and MOST

#Load necessary packages
library(readr)
library(tidyr)
library(dplyr)
library(stringr)

## Load samples
args = commandArgs()
print(args)
# test if there is at least one argument: if not, return an error
if (length(args)!=7) {
  stop("Two arguments (two input files) containing results from SeqSero and MOST should be supplied.n", call.=FALSE)
} else {
  output_dir <- args[6] %>% gsub("/SeqSero_result.txt", x = ., replacement = "")
  res_seqsero <- read_delim(args[6], "\t", col_names = FALSE)
  res_most <- read_csv(args[7], col_names = FALSE)
  res_most <- res_most[1:2,2] %>% str_split(pattern = '\\),')
  res_most <- res_most[[1]][1] %>% str_split(pattern = ',')
  ST_most <- gsub("c\\(", x = res_most[[1]][1], replacement = "") %>% 
    gsub('\\"', x = ., replacement = "")
  prediction_most <- gsub(' \\"\\(', x = res_most[[1]][2], replacement = "") %>% 
    gsub("'", x = ., replacement = "")
  summary <- tibble("Algorithm" = rep(c("SeqSero2", "7 locus-MLST (MOST)"), each = 2),
                    "Type" = c("Antigenic profile", "Serotype", "ST", "Serotype"),
                    "Prediction" = unlist(c(res_seqsero[7:8,2], ST_most, prediction_most)))
  write_csv(summary, paste(output_dir, "final_serotype.csv", sep = "/"))
}