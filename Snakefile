## Pipeline to get SeqSero2 and MOST running
## For now both are run in every sample, but eventually MOST will be run only if SeqSero2 cannot find a serotype
## For now the pipeline needs to be run through my s_serotyper environment (see explanation above seqsero2 rule)

#For now the sample list is loaded here
#sample_list.txt created using script get_sample_list.sh

sample_doc = open("Samples/sample_list.txt", "r")
sample_list = sample_doc.readlines()
sample_list = sample_list[0].split('\n')[:-1]
SAMPLES = sample_list[0].split(' ')

#Not using configfile yet or anything fancy
#configfile: './config_snake/config.yaml'

#Final output is a csv file summarizing results for SeqSero2 and MOST
rule all:
    input:
        expand('Output/{sample}_serotype/final_serotype.csv', sample=SAMPLES),
        'Output/serotype_all_samples.csv'


#This rule gets the serotype prediction using seqsero2
rule seqsero2_prediction:
    input:
        r1 = 'Samples/{sample}_R1.fastq.gz',
        r2 = 'Samples/{sample}_R2.fastq.gz',
    output:
        'Output/{sample}_serotype/SeqSero_result.tsv'
    log:
        'logs/{sample}_seqsero.log'
    threads: 10 
    conda:
        'envs/seqsero.yaml'
    shell:
        'bash Scripts/seqsero2_wrapper.sh {input} > {output}'


#Serotype prediction done with MOST (7 locus-MLST). Only run if SeqSero2 does not give a serotype
rule most_prediction:
    input:
        'Samples/{sample}_R1.fastq.gz',
        'Samples/{sample}_R2.fastq.gz'
    output:
        'Output/{sample}_serotype/{sample}_R1.fastq_MLST_result.csv'
    log:
        'logs/{sample}_most.log'
    threads: 10 
    conda:
        'envs/most.yaml'
    shell:
        'bash Scripts/most_wrapper.sh {input} > {output}'


#Rscript to summarize results from both platforms.
rule final_serotype:
    input:
        'Output/{sample}_serotype/SeqSero_result.tsv',
        'Output/{sample}_serotype/{sample}_R1.fastq_MLST_result.csv'
    output:
        'Output/{sample}_serotype/final_serotype.csv'
    log:
        'logs/{sample}_Rserotype_per_sample.log'
    conda:
        'envs/final_serotype_R.yaml'
    shell:
        'Rscript Scripts/final_serotype.R {input} > {output}'

#Rscript to summarize results for all samples
rule results_all_samples:
    input:
        expand('Output/{sample}_serotype/final_serotype.csv', sample=SAMPLES)
    output:
        'Output/serotype_all_samples.csv'
    log:
        'logs/Rserotype_all_samples.log'
    conda:
        'envs/final_serotype_R.yaml'
    shell:
        'Rscript Scripts/summary_all_samples.R {input} > {output}'

