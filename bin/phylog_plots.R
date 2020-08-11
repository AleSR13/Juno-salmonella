#Set working directory (needs to be gotten from command line if automated)
setwd("/data/BioGrid/hernandez/salmonellaserotyper/")

# Load necessary libraries
library(dplyr)
library(tidyr)
library(ggraph)
library(stringr)
library(igraph)
library(tidygraph)
library(purrr)
library(readr)

#######################################################################################
################################# Own Functions #######################################
#######################################################################################

#Calculate distance matrix from ST
ST_dist <- function(m) {
  d_m<-matrix(0,ncol=nrow(m),nrow=nrow(m))
  for (i in 1:(nrow(m)-1)){
    for (j in (i+1):nrow(m)) {
      dij<-sum(m[i,]!=m[j,])
      d_m[i,j]<-dij
      d_m[j,i]<-dij
    }
  }
  colnames(d_m)<-rownames(m)
  rownames(d_m)<-rownames(m)
  d_m
}


#######################################################################################
###################################### Analysis #######################################
#######################################################################################

# read in a compiled MLST + genes table output by SRST2
mlst_files <- list.files("output/srst2/", pattern = "mlst__Salmonella_enterica__results.txt",
                            full.names = T)
mlst_reports <- map(mlst_files, read_delim, "\t", col_types = "ccccccccccccc")
mlst_compiled <- bind_rows(mlst_reports)

serotype <- read.csv("output/serotype_all_samples.csv", stringsAsFactors = FALSE)

disagreements <- read.csv("comparison_phenotype/serotype_predictedVSphenotypic.csv", stringsAsFactors = F)

#Match all the metadata
mlst_compiled <- mlst_compiled %>% arrange(Sample) %>%
  mutate("Sample" = str_extract(Sample, "^[:alnum:]+"))
serotype <- serotype %>% arrange(Sample)%>%
  mutate("Sample" = str_extract(Sample, "^[:alnum:]+"))
disagreements <- disagreements %>% arrange(Sample)%>%
  mutate("Sample" = str_extract(Sample, "^[:alnum:]+"))

#################### Analysis
# Calculate distance matrix
dist_matrix <- ST_dist(mlst_compiled[-c(1:2)])
colnames(dist_matrix) <- mlst_compiled$Sample
rownames(dist_matrix) <- mlst_compiled$Sample

#Make labels for samples that had disagreements in phenotype and genotype
#"Sample (subsp according to phenotype)"
id_wrong <- ifelse(disagreements$Agree_species == "Disagreement", TRUE, NA)
phenotype <- disagreements$Species[id_wrong]
wrong_subsp <- ifelse(is.na(phenotype), NA, paste0("P: ", phenotype))
#Wrong serotype
id_wrong <- ifelse(disagreements$Agree_serotype=="Disagreement", TRUE, NA)
phenotype <- paste0("P: ", disagreements$phenotypic_serotype[id_wrong], "\nvs G: ", disagreements$Serotype[id_wrong])
wrong_serotype <- ifelse(str_detect(phenotype, "NA"), NA, phenotype)

#Calculate information to build mst graph
mst_tree <- igraph::graph.adjacency(dist_matrix, weighted = TRUE) %>% 
  igraph::mst() %>% 
  as_tbl_graph() %>%
  activate(nodes) %>%
  mutate(subsp = serotype$Subspecies,
         ST = mlst_compiled$ST,
         serotype = serotype$Serotype)

#Plot with all names

#plot(mst_tree)
ggraph(mst_tree, layout = 'kk') + 
  geom_edge_link() +
  geom_node_point(aes(colour = ST), size = 7) +  
  labs(title = expression(paste('MST (based on 7-locus MLST) ', italic('Salmonella'), ' samples'))) + 
  theme_graph()
ggsave("comparison_phenotype/MST_7locus_ST.jpeg", height = 21, width = 27, units = "cm")


ggraph(mst_tree, layout = 'kk') + 
  geom_edge_link() +
  geom_node_point(aes(colour = subsp), size = 7) + 
  geom_node_text(aes(label = name), colour = 'black', vjust = 0.4, size = 3.2) + 
  scale_color_discrete(name = "Subspecies", 
                       labels = c("S. bongori", "S. enterica sbsp enterica", "S. enterica sbsp salamae",
                                  "S. enterica sbsp arizonae", "S. enterica sbsp diarizonae", 
                                  "S. enterica sbsp houtenae", "S. enterica sbsp indica")) +
  labs(title = expression(paste('MST (based on 7-locus MLST) ', italic('Salmonella'), ' samples'))) + 
  theme_graph()

ggsave("comparison_phenotype/MST_7locus_sbsp.jpeg", height = 21, width = 23, units = "cm")

#Plot only the ones with disagreement in subspecies
#Make labels for samples that had disagreements in phenotype and genotype
#"Sample (subsp according to phenotype)"
id_wrong <- ifelse(disagreements$Agree_species == "Disagreement", TRUE, NA)
phenotype <- disagreements$Species[id_wrong]
wrong_subsp <- ifelse(is.na(wrong_subsp), NA, paste0("P: ", phenotype))

#Plot
ggraph(mst_tree, layout = 'kk') + 
  geom_edge_link() +
  geom_node_point(aes(colour = ifelse(is.na(wrong_subsp), NA, "red")), size = 7) +
  geom_node_point(aes(colour = subsp), size = 5) +
  geom_node_text(aes(label = wrong_subsp), colour = 'black', vjust = 0.4, size = 3.2) + 
  scale_color_discrete(name = "Subspecies", 
                       labels = c("S. bongori", "S. enterica sbsp enterica", "S. enterica sbsp salamae",
                                  "S. enterica sbsp arizonae", "S. enterica sbsp diarizonae", 
                                  "S. enterica sbsp houtenae", "S. enterica sbsp indica")) +
  labs(title = expression(paste('MST (based on 7-locus MLST) ', italic('Salmonella'), ' samples'))) + 
  theme_graph()

ggsave("comparison_phenotype/MST_7locus_subsp_disagree.jpeg", height = 21, width = 23, units = "cm")

#Plot only the ones with disagreement in serotype
#Make labels for samples that had disagreements in phenotype and genotype
#Wrong serotype
id_wrong <- ifelse(disagreements$Agree_serotype=="Disagreement", TRUE, NA)
phenotype <- paste0("P: ", disagreements$phenotypic_serotype[id_wrong], " vs G: ", disagreements$Serotype[id_wrong])
wrong_serotype <- ifelse(str_detect(phenotype, "NA"), NA, phenotype)
wrong_serotype_samples <- disagreements$Sample[id_wrong]
#Plot
ggraph(mst_tree, layout = 'kk') + 
  geom_edge_link() +
  geom_node_point(aes(colour = ifelse(is.na(wrong_serotype), NA, "wrong")), size = 7, show.legend = FALSE) +
  geom_node_point(aes(colour = subsp), size = 5, show.legend = FALSE) + 
  geom_node_text(aes(label = wrong_serotype_samples), colour = "black", vjust = 0.4, size = 3.2) + 
  labs(title = expression(paste('MST (based on 7-locus MLST) ', italic('Salmonella'), ' samples'))) + 
  theme_graph()

ggsave("comparison_phenotype/MST_7locus_serotype_disagree.jpeg", height = 21, width = 23, units = "cm")

serotype_pvsg <- tibble("Sample" = wrong_serotype_samples[!is.na(wrong_serotype_samples)],
                   "Serotype" = wrong_serotype[!is.na(wrong_serotype)])
write.csv(serotype_pvsg, "comparison_phenotype/serotype_figtable.csv")

####### Clustering
clust_res <- hclust(as.dist(dist_matrix),"single") %>% 
  as_tbl_graph %>%
  activate(nodes) %>%
  mutate(subsp = serotype$Subspecies[match(label, serotype$Sample)],
         serotype_g = serotype$Serotype[match(label, serotype$Sample)],
         wrong_serotype = wrong_serotype[match(label, serotype$Sample)],
         wrong_subsp = wrong_subsp[match(label, serotype$Sample)])

ggraph(clust_res, layout = 'dendrogram') + 
  geom_node_point(aes(color = subsp))+
  scale_color_discrete(name = "Subspecies (genotypic prediction):", 
                       labels = c("S. bongori", "S. enterica sbsp enterica", "S. enterica sbsp salamae",
                                  "S. enterica sbsp arizonae", "S. enterica sbsp diarizonae", 
                                  "S. enterica sbsp houtenae", "S. enterica sbsp indica")) +
  geom_edge_elbow()+
  geom_node_text(aes(label=wrong_subsp), angle = 90, hjust = 1.05)+
  ylim(-18,NA) +
  labs(title = "Hierarchical clustering using 7-locus MLST data",
       xlab = "Subspecies as predicted phenotypically")+
  theme_graph()
  
ggsave("comparison_phenotype/hclust_7locus.jpeg", height = 17, width = 31, units = "cm")

