#Rscript to summarize results for all samples
rule salmonella_serotype_multireport:
    input:
        expand(OUT+'/{sample}_serotype/SeqSero_result.tsv', sample=SAMPLES)
    output:
        OUT+'/salmonella_multi_report.csv'
    benchmark:
        OUT+'/log/benchmark/Rserotype_all_samples.log'
    log:
        OUT+'/log/Rserotype_all_samples.log'
    shell:
        'python bin/seqsero2_multireport.py -i {input} -o {output} 2> {log}'



