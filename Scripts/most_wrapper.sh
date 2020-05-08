#!/bin/bash/

#Create list of arguments to be used in the script
sample_r1="$1" 	#As assigned in Snakefile
sample_r2="$2" 	#As assigned in Snakefile
mlst_data_dir="Scripts/MOST/MLST_data/salmonella/"
sample_name=${sample_r1%_R1.fastq.gz}
sample_name=${sample_name#Samples/}
output_dir="Output/${sample_name}_serotype/"


###########################################################################################################################################
##############     Check if MOST needs to be run and run it only if SeqSero2 could not predict serotype   #################################
###########################################################################################################################################


#Read results from SeqSero2 and save the antigenic profile and the serotype predictions
serotype=`grep 'serotype:' ${output_dir}/SeqSero_result.tsv`
serotype=`echo ${serotype#*:}`


#Run MOST only if antigenic profile predicted by SeqSero2 is the same than the serotype (so no serotype name was found)
if [[ $serotype == *:*:* ]]; then
    Scripts/MOST/MOST.py -1 $sample_r1 -2 $sample_r2 -st $mlst_data_dir -o $output_dir -serotype True
else
    echo "SeqSero2 predicted serotype. No need to run MOST for sample ${sample_name}"
fi

