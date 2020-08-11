setwd("/data/BioGrid/hernandez/salmonellaserotyper/")

library(readxl)
library(readr)
library(stringr)
library(dplyr)
library(ggplot2)


#Load data my results and the true phenotype
report_ngs_serotyper <- read_csv("output/serotype_all_samples.csv", col_types = "cccccccf") %>%
  mutate("Nummer" = as.numeric(str_extract(Sample, "^\\d*")))
levels(report_ngs_serotyper$Subspecies) <- c("S. bongori", 
                                             "S. enterica subsp. houtenae",
                                             "S. enterica subsp. arizonae",
                                             "S. enterica subsp. enterica",
                                             "S. enterica subsp. salamae",
                                             "S. enterica subsp. diarizonae")

true_phenotype <- read_excel("comparison_phenotype/Salmonella_fenotype.xlsx") %>%
  .[1:3]
names(true_phenotype)[3] <- "phenotypic_serotype"


#Build table comparing results of subspecies prediction
comparison <- left_join(report_ngs_serotyper, true_phenotype, by = "Nummer") %>%
  .[c("Sample", "Species", "phenotypic_serotype", "Subspecies", "Serotype")] %>%
  mutate("Agree_species" = ifelse(Species == Subspecies, "Agreement", "Disagreement"),
         "Agree_serotype" = ifelse(phenotypic_serotype == Serotype, "Agreement", "Disagreement")) 

write.csv(comparison, "comparison_phenotype/serotype_predictedVSphenotypic.csv")

#Build second table with only results for salmonella enterica
enterica <- filter(comparison, str_detect(comparison$Subspecies, "subsp. enterica") |
                   str_detect(comparison$Species, "subsp. enterica")) 

write.csv(enterica, "comparison_phenotype/enterica_samples.csv")


##Plots
ggplot(comparison, aes(x = Agree_species, fill = Agree_species))+
  geom_bar(show.legend = FALSE)+
  scale_fill_manual(values = c("darkorange", "gray"))+
  labs(title = expression(paste("Prediction of ", italic("Salmonella"), " subspecies")),
       subtitle = "Prediction based on genotype (NGS data) vs phenotype measurement",
       x = NULL, y = "Count") +
  theme_light()
ggsave("comparison_phenotype//Subspecies_comparison.jpeg", width = 15, height = 13, units = "cm")

# Enterica
enterica$Agree_serotype[is.na(enterica$Agree_serotype)] <- "No phenotype reported"
ggplot(enterica, aes(x = Agree_serotype, fill = Agree_serotype))+
  geom_bar(show.legend = FALSE)+
  scale_fill_manual(values = c("darkorange", "gray", "lightgray"))+
  labs(title = expression(paste("Prediction of ", italic("Salmonella"), " serotype (enriching for rare serotypes)")),
       subtitle = "Prediction based on genotype (NGS data) vs phenotype measurement",
       caption = "No phenotype reported: when subspecies disagreed",
       x = NULL, y = "Count") +
  theme_light()
ggsave("comparison_phenotype//Serotype_comparison.jpeg", width = 15, height = 13, units = "cm")
