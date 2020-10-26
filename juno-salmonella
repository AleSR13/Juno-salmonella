#!/bin/bash
###############################################################################################################################################
### Juno pipeline-Salmonella                                                                                                                ### 
### Authors: Alejandra Hernandez-Segura, Maaike van der Beld                                                                                ### 
### Organization: Rijksinstituut voor Volksgezondheid en Milieu (RIVM)                                                                      ### 
### Department: Infektieziekteonderzoek, Diagnostiek en Laboratorium Surveillance (IDS), Bacteriologie (BPD)                                ### 
### Date: 09-10-2020                                                                                                                        ### 
###                                                                                                                                         ### 
### Documentation: https://gitl01-int-p.rivm.nl/hernanda/test1_salmonellaserotyper                                                          ### 
###                                                                                                                                         ### 
###                                                                                                                                         ### 
###############################################################################################################################################

#load in functions
set -o allexport
source bin/functions.sh
eval "$(parse_yaml config/parameters.yaml "params_")"
eval "$(parse_yaml config/config.yaml "configuration_")"
set +o allexport

UNIQUE_ID=$(bin/generate_id.sh)
SET_HOSTNAME=$(bin/gethostname.sh)


### conda environment
PATH_MASTER_YAML="envs/master_env.yaml"
MASTER_NAME=$(head -n 1 ${PATH_MASTER_YAML} | cut -f2 -d ' ') # Extract Conda environment name as specified in yaml file


### Default values for CLI parameters
INPUT_DIR="samples"
OUTPUT_DIR="out"
SKIP_CONFIRMATION="FALSE"
SNAKEMAKE_UNLOCK="FALSE"
CLEAN="FALSE"
HELP="FALSE"
MAKE_SAMPLE_SHEET="FALSE"
SHEET_SUCCESS="FALSE"
DRY_RUN="FALSE"

### Parse the commandline arguments, if they are not part of the pipeline, they get send to Snakemake
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -i|--input)
        INPUT_DIR="$2"
        shift # Next
        shift # Next
        ;;
        -o|--output)
        OUTPUT_DIR="$2"
        shift # Next
        shift # Next
        ;;
        -h|--help)
        HELP="TRUE"
        shift # Next
        ;;
        -sh|--snakemake-help)
        SNAKEMAKE_HELP="TRUE"
        shift # Next
        ;;
        --clean)
        CLEAN="TRUE"
        shift # Next
        ;;
        --make-sample-sheet)
        MAKE_SAMPLE_SHEET="TRUE"
        shift # Next
        ;;
        -y)
        SKIP_CONFIRMATION="TRUE"
        shift # Next
        ;;
        -n|--dry_run)
        DRY_RUN="TRUE"
        shift # Next
        ;;
        -u|--unlock)
        SNAKEMAKE_UNLOCK="TRUE"
        shift # Next
        ;;
        *) # Any other option
        POSITIONAL+=("$1") # save in array
        shift # Next
        ;;
    esac
done
set -- "${POSITIONAL[@]:-}" # Restores the positional arguments (i.e. without the case arguments above) which then can be called via `$@` or `$[0-9]` etc. These parameters are send to Snakemake.


### Print help message
if [ "${HELP:-}" == "TRUE" ]; then
    line
    cat <<HELP_USAGE
Juno pipeline-Salmonella, built with Snakemake
  Usage: bash $0 -i <INPUT_DIR> <parameters>
  N.B. it is designed for Illumina paired-end data only

Input:
  -i, --input [DIR]                 This is the folder containing your input fastq files.
                                    Default is 'samples/' 
  -o, --output [DIR]                This is the folder where the result files will be collected.
                                    Default is 'out/' 
Output (automatically generated):
  data/                             Contains detailed intermediate files.
  logs/                             Contains all log files.
  results/                          Contains all final results, these are visualized via the
                                    web-report (Notebook_report.ipynb).
Parameters:
  -h, --help                        Print the help document.
  -sh, --snakemake-help             Print the Snakemake help document.
  --clean (-y)                      Removes output. (-y forces "Yes" on all prompts)
  -n, --dry-run                     Useful snakemake command: Do not execute anything, and
                                    display what would be done.
  -u, --unlock                      Removes the lock on the working directory. This happens when
                                    a run ends abruptly and prevents you from doing subsequent
                                    analyses.
  -q, --quiet                       Useful snakemake command: Do not output any progress or
                                    rule information.

HELP_USAGE
    exit 0
fi





### Remove all output
if [ "${CLEAN:-}" == "TRUE" ]; then
    bash bin/Clean
    exit 0
fi



#### MAKE SURE CONDA WORKS ON ALL SYSTEMS
rcfile="${HOME}/.Juno_salmonella_src"
conda_loc=$(which conda)


if [ ! -f "${rcfile}" ]; then
    if [ ! -z "${conda_loc}" ]; then

    #> I ripped this block from jovian
    #> Check https://github.com/DennisSchmitz/Jovian for the source code
    #> The specific file is bin/includes/Install_miniconda
    #> relevant lines are FROM line #51
    #>

    condadir="${conda_loc}"
    basedir=$(echo "${condadir}" | rev | cut -d'/' -f3- | rev)
    etcdir="${basedir}/etc/profile.d/conda.sh"
    bindir="${basedir}/bin"

    touch "${rcfile}"
    cat << EOF >> "${rcfile}"
if [ -f "${etcdir}" ]; then
    . "${etcdir}"
else
    export PATH="${bindir}:$PATH"
fi

export -f conda
export -f __conda_activate
export -f __conda_reactivate
export -f __conda_hashr
export -f __add_sys_prefix_to_path
EOF

    cat << EOF >> "${HOME}/.bashrc"
if [ -f "${rcfile}" ]; then
    . "${rcfile}"
fi
EOF

    fi 

fi



source "${HOME}"/.bashrc




###############################################################################################################
##### Installation block                                                                                  #####
###############################################################################################################

### Pre-flight check: Assess availability of required files, conda and master environment
if [ ! -e "${PATH_MASTER_YAML}" ]; then # If this yaml file does not exist, give error.
    line
    spacer
    echo -e "ERROR: Missing file \"${PATH_MASTER_YAML}\""
    exit 1
fi

if [[ $PATH != *${MASTER_NAME}* ]]; then # If the master environment is not in your path (i.e. it is not currently active), do...
    line
    spacer
    set +ue # Turn bash strict mode off because that breaks conda
    conda activate "${MASTER_NAME}" # Try to activate this env
    if [ ! $? -eq 0 ]; then # If exit statement is not 0, i.e. master conda env hasn't been installed yet, do...
        #installer_intro
        if [ "${SKIP_CONFIRMATION}" = "TRUE" ]; then
            echo -e "\tInstalling master environment..." 
            conda env create -f ${PATH_MASTER_YAML} 
            conda activate "${MASTER_NAME}"
            echo -e "DONE"
        else
            while read -r -p "The master environment hasn't been installed yet, do you want to install this environment now? [y/N] " envanswer
            do
                envanswer=${envanswer,,}
                if [[ "${envanswer}" =~ ^(yes|y)$ ]]; then
                    echo -e "\tInstalling master environment..." 
                    conda env create -f ${PATH_MASTER_YAML}
                    conda activate "${MASTER_NAME}"
                    echo -e "DONE"
                    break
                elif [[ "${envanswer}" =~ ^(no|n)$ ]]; then
                    echo -e "The master environment is a requirement. Exiting because cannot continue without this environment"
                    exit 1
                else
                    echo -e "Please answer with 'yes' or 'no'"
                fi
            done
        fi
    fi
    set -ue # Turn bash strict mode on again
    echo -e "Succesfully activated master environment"
fi


if [ "${SNAKEMAKE_UNLOCK}" == "TRUE" ]; then
    printf "\nUnlocking working directory...\n"
    snakemake -s Snakefile --profile config --config output_dir='${OUTPUT_DIR}' ${@} --unlock
    printf "\nDone.\n"
    exit 0
fi


### Print Snakemake help
if [ "${SNAKEMAKE_HELP:-}" == "TRUE" ]; then
    line
    snakemake --help
    exit 0
fi


### Pass other CLI arguments along to Snakemake
if [ ! -d "${INPUT_DIR}" ]; then
    minispacer
    echo -e "The input directory specified (${INPUT_DIR}) does not exist"
    echo -e "Please specify an existing input directory"
    minispacer
    exit 1
fi

########################## Initialize pipeline ############################################

### Generate sample sheet
if [  `ls -A "${INPUT_DIR}" | grep 'R[0-9]\{1\}.*\.f[ast]\{0,3\}q\.\?[gz]\{0,2\}$' | wc -l` -gt 0 ]; then
    minispacer
    echo -e "Files in input directory (${INPUT_DIR}) are present"
    echo -e "Generating sample sheet..."
    python bin/generate_sample_sheet.py "${INPUT_DIR}" > sample_sheet.yaml
    if [ $(wc -l sample_sheet.yaml | awk '{ print $1 }') -gt 2 ]; then
        SHEET_SUCCESS="TRUE"
    fi
else
    minispacer
    echo -e "The input directory you specified (${INPUT_DIR}) exists but is empty or does not contain the expected input files...\nPlease specify a directory with input-data."
    exit 0
fi

### Checker for succesfull creation of sample_sheet
if [ "${SHEET_SUCCESS}" == "TRUE" ]; then
    echo -e "Succesfully generated the sample sheet"
    echo -e "ready_for_start"
else
    echo -e "Couldn't find files in the input directory that ended up being in a .FASTQ, .FQ or .GZ format. \nIt could also be that your file names do not contain the letters 'pR1' or 'pR2' to designate the filtered/trimmed forward and reverse reads."
    echo -e "Please inspect the input directory (${INPUT_DIR}) and make sure the files are in one of the formats listed below"
    echo -e ".fastq.gz (Zipped Fastq)"
    echo -e ".fq.gz (Zipped Fq)"
    echo -e ".fastq (Unzipped Fastq)"
    echo -e ".fq (unzipped Fq)"
    exit 1
fi


if [ "${MAKE_SAMPLE_SHEET}" == "TRUE" ]; then
    echo -e "salmonella_pipeline_run:\n    identifier: ${UNIQUE_ID}" > variables.yaml
    echo -e "Server_host:\n    hostname: http://${SET_HOSTNAME}" >> variables.yaml
    echo -e "The sample sheet and variables file has now been created, you can now run the snakefile manually"
    exit 0
fi

### Dry run
if [ "${DRY_RUN}" == "TRUE" ]; then
    snakemake --profile config --config output_dir=${OUTPUT_DIR} ${@} -n
    exit 0 
fi


### Actual snakemake command with checkers for required files. N.B. here the UNIQUE_ID and SET_HOSTNAME variables are set!
if [ -e sample_sheet.yaml ]; then
    echo -e "Starting snakemake"
    set +ue #turn off bash strict mode because snakemake and conda can't work with it properly
    echo -e "Juno_salmonella_run:\n    identifier: ${UNIQUE_ID}" > variables.yaml
    echo -e "Server_host:\n    hostname: http://${SET_HOSTNAME}" >> variables.yaml
    eval $(parse_yaml variables.yaml "config_")
    snakemake --profile config --config output_dir=${OUTPUT_DIR} --drmaa " -q bio -n {threads}" --drmaa-log-dir ${OUTPUT_DIR}/log/drmaa ${@}
    #echo -e "\nUnique identifier for this run is: $config_run_identifier "
    echo -e "Juno Salmonella pipeline run complete"
    set -ue #turn bash strict mode back on
else
    echo -e "Sample_sheet.yaml could not be found"
    echo -e "This also means that the pipeline was unable to generate a new sample sheet"
    echo -e "Please inspect the input directory (${INPUT_DIR}) and make sure the right files are present"
    exit 1
fi

exit 0 
