# Juno-Salmonella pipeline

This small pipeline predicts the serotype of Salmonella samples from fastq files. It uses the tool SeqSero2 to do so (see: https://github.com/denglab/SeqSero2). It contains only two rules:
1. Serotype prediction using SeqSero2 taking fastq files as input
2. Creates a salmonella\_multi_report.csv that collects all the results from all the samples run

_Note:_ SeqSero2 is run in microassembly mode and, in this pipeline, it can only accept two separate fastq files (one for forward and one for reverse reads). 

## Usage

There are some parameters that can be changed. For instance, this pipeline automatically creates one new folder (or uses an existing one) called 'output/' in the current directory. You can change this behaviour by modifying the file config.yaml that is located in the 'config/' folder. Just go to the 'config:' section inside the config.yaml and change the "output\_dir='output'" to "output\_dir='your\_output\_dir'" where 'your\_output\_dir' can be any folder name or folder path you want.

Once you have done that, you can just run the pipeline by typing in your command line:

```bash start_pipeline.sh -i <path_to_fastq_files> -o <path_to_desired_output_folder>```

where the <path_to_fastq_files> is the input directory (`-i`) given either as an absolute path or as a path relative to your current directory. The same counts for your desired output directory (`-o`).


The pipeline also accepts other input that can be passed to snakemake. You can display the different options by typing:

```bash juno-salmonella -h```

or   

```bash juno-salmonella --help```
