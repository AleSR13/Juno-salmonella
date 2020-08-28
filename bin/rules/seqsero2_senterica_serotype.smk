#This rule gets the serotype prediction using seqsero2
rule seqsero2_senterica_serotype:
    input:
        r1 = lambda wildcards: SAMPLES[wildcards.sample]['R1'],
        r2 = lambda wildcards: SAMPLES[wildcards.sample]['R2']
    output:
        OUT+'/{sample}_serotype/SeqSero_result.tsv'
    benchmark:
        OUT+'/log/benchmark/{sample}_seqsero.log'
    log:
        OUT+'/log/{sample}_seqsero.log'
    params:
        output_dir = OUT+'/{sample}_serotype/'
    threads: 
        config["threads"]["SeqSero2_Serotype"]
    conda:
        '../../envs/seqsero.yaml'
    shell:
        """
#Run seqsero2 
# -m 'a' means microassembly mode and -t '2' refers to separated fastq files (no interleaved)
SeqSero2_package.py -m 'a' -t '2' -i {input} -d {params.output_dir} -p {threads}
        """
