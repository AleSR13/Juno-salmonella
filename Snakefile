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
        expand('Output_{sample}/final_serotype.csv', sample=SAMPLES)


#This rule gets the serotype prediction using seqsero2
#For now it uses the 'k-mer' mode, but eventually I would like to go for 'microassembly'
#Using kmer for now because it is faster (according to authors) so better for tests
#This rule works fine except that it cannot use the conda environment
#the SeqSero1_package.py has a bug that cannot find 'antigens.pickle'
#problem easily fixable in my own environment, but not while generating an environment through yaml, 
#so for now I need to run the pipeline through my conda environment 's_serotyper'
rule seqsero2_prediction:
    input:
        r1 = 'Samples/{sample}_R1.fastq.gz',
        r2 = 'Samples/{sample}_R2.fastq.gz',
    output:
        'Output_{sample}/SeqSero_result.txt'
    log:
        'logs/{sample}_seqsero.log'
    threads: 4 
    #conda:
        #'envs/seqsero.yaml'
    shell:
        'bash Scripts/seqsero2_wrapper.sh {input.r1} {input.r2} > {output}'


#It is not working! It has trouble finding the output file 
#No clue what the error is. Wrapper works fine from command line
rule most_prediction:
    input:
        'Samples/{sample}_R1.fastq.gz',
        'Samples/{sample}_R2.fastq.gz'
    output:
        'Output_{sample}/MOST_res/{sample}_R1.fastq_MLST_result.csv'
    log:
        'logs/{sample}_most.log'
    threads: 4 
    conda:
        'envs/most.yaml'
    shell:
        'bash Scripts/seqsero2_wrapper.sh {input} > {output}'


#Rscript to summarize results from both platforms.
#Need to modify it after modifying the pipeline to only run MOST if SeqSero2 does not work
rule final_serotype:
    input:
        'Output_{sample}/SeqSero_result.txt',
        'Output_{sample}/MOST_res/{sample}_R1.fastq_MLST_result.csv'
    output:
        'Output_{sample}/final_serotype.csv'
    log:
        'logs/{sample}_Rfinal.log'
    conda:
        'envs/final_serotype_R.yaml'
    shell:
        'Rscript Scripts/final_serotype.R {input} > {output}'
