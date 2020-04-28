#!/bin/bash/

##Script to serotype Salmonella using SeqSero2. If this fails, use MOST

#Create list of arguments (referring to Snakemake)
sample_r1="$1"
sample_r2="$2"
sample_name=${sample_r1%_R1.fastq.gz}
sample_name=${sample_name#Samples/}
output_dir="Output_${sample_name}/"

mkdir -p $output_dir

#Run seqsero2 for each sample and store it in the output folder under its name
SeqSero2_package.py -m 'k' -t '2' -i $sample_r1 $sample_r2 -d $output_dir


