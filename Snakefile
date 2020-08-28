## Pipeline to get serotype of Salmonella samples from fastq files
## The pipline uses SeqSero2 as main tool but when it fails to get a serotype, 
## it inferes it from the 7-gene MLST
# Snakemake rules (in order of execution):
#   1 SeqSero2_Serotype: predicts serotype using SeqSero2 package 
#   2 salmonella_multi_report: generates one salmonella_multi_report.csv file with the results of all samples 
##


#import pathlib
#import pprint
import yaml

#Configuration options for snakemake
configfile: 'config/config.yaml'
configfile: 'config/parameters.yaml'

# Load sample list (YAML file with form: sample > read number > file)
SAMPLES = {}
with open(config["sample_sheet"]) as sample_sheet_file:
    SAMPLES = yaml.safe_load(sample_sheet_file) 




# Local rules
localrules:
    all,
    salmonella_multi_report

#Final output is a csv file summarizing results for SeqSero2 and MOST
rule all:
    input:
        expand(config["output_dir"]+'/{sample}_serotype/SeqSero_result.tsv', sample=SAMPLES),
        config["output_dir"]+'/salmonella_multi_report.csv'     


#This rule gets the serotype prediction using seqsero2
rule SeqSero2_Serotype:
    input:
        r1 = lambda wildcards: SAMPLES[wildcards.sample]['R1'],
        r2 = lambda wildcards: SAMPLES[wildcards.sample]['R2']
    output:
        config["output_dir"]+'/{sample}_serotype/SeqSero_result.tsv'
    benchmark:
        config["output_dir"]+'/log/benchmark/{sample}_seqsero.log'
    log:
        config["output_dir"]+'/log/{sample}_seqsero.log'
    params:
        output_dir = config["output_dir"]+'/{sample}_serotype/'
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


#Rscript to summarize results for all samples
rule salmonella_multi_report:
    input:
        expand(config["output_dir"]+'/{sample}_serotype/SeqSero_result.tsv', sample=SAMPLES)
    output:
        config["output_dir"]+'/salmonella_multi_report.csv'
    benchmark:
        config["output_dir"]+'/log/benchmark/Rserotype_all_samples.log'
    log:
        config["output_dir"]+'/log/Rserotype_all_samples.log'
    conda:
        'envs/final_serotype_R.yaml'
    shell:
        'Rscript bin/seqsero2_multireport.R {output} {input} 2> {log}'



