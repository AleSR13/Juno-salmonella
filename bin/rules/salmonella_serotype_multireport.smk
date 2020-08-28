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
    conda:
        '../../envs/final_serotype_R.yaml'
    shell:
        'Rscript bin/seqsero2_multireport.R {output} {input} 2> {log}'



