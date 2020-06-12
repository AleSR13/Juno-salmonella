## Pipeline to get serotype of Salmonella samples from fastq files
## The pipline uses SeqSero2 as main tool but when it fails to get a serotype, 
## it inferes it from the 7-gene MLST
# Snakemake rules (in order of execution):
#   1 SeqSero2 
#   2 MOST (only run if SeqSero2 fails to predict serotype)
## For now MOST is in my Scripts folder. Eventually I want to have it as an installable software
#   3 final_serotype: creates summary table per sample with results from seqsero2 and most
#   4 summary_all_samples: generates one summary file and one report file with the results of all samples run
## The summary_all_samples file has more detail (antigenic profile, full result from seqsero2 and from most, subspecies, etc)
## The report file only contains a table of samples and their final predicted serotype


import pathlib
import pprint
import yaml

#Configuration options for snakemake
configfile: "config/config.yaml"
configfile: 'config/parameters.yaml'

# Load sample list (YAML file with form: sample > read number > file)
SAMPLES = {}
with open(config["sample_sheet"]) as sample_sheet_file:
    SAMPLES = yaml.load(sample_sheet_file) 

#Final output is a csv file summarizing results for SeqSero2 and MOST
rule all:
    input:
        expand('output/{sample}_serotype/SeqSero_result.tsv', sample=SAMPLES),
        expand('output/{sample}_serotype/{sample}.fastq_MLST_result.csv', sample=SAMPLES),
        expand('output/{sample}_serotype/final_serotype.csv', sample=SAMPLES),
        'output/serotype_report.csv',
        'output/serotype_all_samples.csv'


#This rule gets the serotype prediction using seqsero2
rule SeqSero2_Serotype:
    input:
        r1 = lambda wildcards: SAMPLES[wildcards.sample]['R1'],
        r2 = lambda wildcards: SAMPLES[wildcards.sample]['R2']
    output:
        'output/{sample}_serotype/SeqSero_result.tsv'
    log:
        'output/log/{sample}_seqsero.log'
    params:
        output_dir = 'output/{sample}_serotype/'
    threads: 
        config["threads"]["SeqSero2_Serotype"]
    conda:
        'envs/seqsero.yaml'
    shell:
        """
#Run seqsero2 
# -m 'a' means microassembly mode and -t '2' refers to separated fastq files (no interleaved)
SeqSero2_package.py -m 'a' -t '2' -i {input} -d {params.output_dir} -p {threads}
        """


#Serotype prediction done with MOST (7 locus-MLST). Only run if SeqSero2 does not give a serotype
rule MOST_Serotype:
    input:
        r1 = lambda wildcards: SAMPLES[wildcards.sample]['R1'],
        r2 = lambda wildcards: SAMPLES[wildcards.sample]['R2'],
        seqsero_res = 'output/{sample}_serotype/SeqSero_result.tsv'
    output:
        'output/{sample}_serotype/{sample}.fastq_MLST_result.csv'
    log:
        'output/log/{sample}_most.log'
    params:
        output_dir='output/{sample}_serotype/',
        mlst_db=config["MOST"]["mlst_db"]
    threads: 10 
    conda:
        'envs/most.yaml'
    shell:
        """
#Read results from SeqSero2 

while IFS=$'\t' read -r -a myArray
do
    serotype=`echo "${{myArray[8]}}"`
done < {input.seqsero_res}

#Run MOST only if SeqSero2 could not predict serotype (serotype has the form: antigen:antigen:antigen)
if [[ $serotype == *:*:* ]]; then
    scripts/MOST/MOST.py -1 {input.r1} \
    -2 {input.r2} \
    -st {params.mlst_db} \
    -o {params.output_dir} \
    -serotype True
    result=(`ls {params.output_dir} | grep 'MLST_result.csv'`)
    mv "{params.output_dir}/${{result}}" {output}
else
    echo "SeqSero2 predicted serotype. No need to run MOST" > {output}
fi
        """



#Rscript to summarize results from both platforms.
rule Final_Serotype_per_sample:
    input:
        'output/{sample}_serotype/SeqSero_result.tsv',
        'output/{sample}_serotype/{sample}.fastq_MLST_result.csv'
    output:
        'output/{sample}_serotype/final_serotype.csv'
    log:
        'output/log/{sample}_Rserotype_per_sample.log'
    conda:
        'envs/final_serotype_R.yaml'
    shell:
        'Rscript scripts/final_serotype.R {input} > {output} 2> {log}'



#Rscript to summarize results for all samples
rule Serotype_All_Samples:
    input:
        expand('output/{sample}_serotype/final_serotype.csv', sample=SAMPLES)
    output:
        'output/serotype_all_samples.csv',
        'output/serotype_report.csv'
    log:
        'output/log/Rserotype_all_samples.log'
    conda:
        'envs/final_serotype_R.yaml'
    shell:
        'Rscript scripts/summary_all_samples.R {input} 2> {log}'

