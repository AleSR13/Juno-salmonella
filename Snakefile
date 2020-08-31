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

# Easy access output directory
OUT = config["output_dir"]

#@################################################################################
#@#### 				Processes                                    #####
#@################################################################################

    #############################################################################
    #####  			Salmonella Serotyping                       #####
    #############################################################################

include: "bin/rules/seqsero2_senterica_serotype.smk"
include: "bin/rules/salmonella_serotype_multireport.smk"


#@################################################################################
#@#### The `onstart` checker codeblock                                       #####
#@################################################################################

onstart:
    try:
        print("Checking if all specified files are accessible...")
        important_files = [ config["sample_sheet"] ]
        for filename in important_files:
            if not os.path.exists(filename):
                raise FileNotFoundError(filename)
    except FileNotFoundError as e:
        print("This file is not available or accessible: %s" % e)
        sys.exit(1)
    else:
        print("\tAll specified files are present!")
    shell("""
        mkdir -p {OUT}
        mkdir -p {OUT}/results
        echo -e "\nLogging pipeline settings..."
        echo -e "\tGenerating methodological hash (fingerprint)..."
        echo -e "This is the link to the code used for this analysis:\thttps://gitl01-int-p.rivm.nl/hernanda/test1_salmonellaserotyper/tree/$(git log -n 1 --pretty=format:"%H")" > '{OUT}/results/log_git.txt'
        echo -e "This code with unique fingerprint $(git log -n1 --pretty=format:"%H") was committed by $(git log -n1 --pretty=format:"%an <%ae>") at $(git log -n1 --pretty=format:"%ad")" >> '{OUT}/results/log_git.txt'
        echo -e "\tGenerating full software list of current Conda environment (\"salmonella_master\")..."
        conda list > '{OUT}/results/log_conda.txt'
        echo -e "\tGenerating config file log..."
        rm -f '{OUT}/results/log_config.txt'
        for file in config/*.yaml
        do
            echo -e "\n==> Contents of file \"${{file}}\": <==" >> '{OUT}/results/log_config.txt'
            cat ${{file}} >> '{OUT}/results/log_config.txt'
            echo -e "\n\n" >> '{OUT}/results/log_config.txt'
        done
    """)

#@################################################################################
#@#### These are the conditional cleanup rules                               #####
#@################################################################################

#onerror:
 #   shell("""""")


onsuccess:
    shell("""
        echo -e "\tGenerating HTML index of log files..."
        echo -e "\tGenerating Snakemake report..."
        snakemake --profile config --unlock
        snakemake --profile config --report '{OUT}/results/snakemake_report.html'
        echo -e "Finished"
    """)


#################################################################################
##### Specify final output:                                                 #####
#################################################################################

# Local rules
localrules:
    all,
    salmonella_serotype_multireport


rule all:
    input:
        expand(OUT+'/{sample}_serotype/SeqSero_result.tsv', sample=SAMPLES),
        OUT+'/salmonella_multi_report.csv' 


