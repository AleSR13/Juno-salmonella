#!/bin/bash/

#Create list of arguments
sample_r1="$1"
sample_r2="$2"
mlst_data_dir="Scripts/MOST/MLST_data/salmonella/"
sample_name=${sample_r1%_R1.fastq.gz}
sample_name=${sample_name#Samples/}
output_dir="Output_${sample_name}/MOST_res/"

#Run MOST

Scripts/MOST/MOST.py -1 $sample_r1 -2 $sample_r2 -st $mlst_data_dir -o $output_dir -serotype True


