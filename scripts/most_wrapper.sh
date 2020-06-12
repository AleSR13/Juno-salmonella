#!/bin/bash/

#Create list of arguments to be used in the script
sample_r1="$1" 	#As assigned in Snakefile
sample_r2="$2" 	#As assigned in Snakefile
seqsero_res="$3" 	#As assigned in Snakefile
output_dir=${seqsero_res%SeqSero_result.tsv}
mlst_data_dir="$4" 	#As assigned in Snakefile (from parameters)




###########################################################################################################################################
##############     Check if MOST needs to be run and run it only if SeqSero2 could not predict serotype   #################################
###########################################################################################################################################


#Read results from SeqSero2 and save the antigenic profile and the serotype predictions
serotype=`grep 'serotype:' $seqsero_res`
serotype=`echo ${serotype#*:}`


#Run MOST only if antigenic profile predicted by SeqSero2 is the same than the serotype (so no serotype name was found)
if [[ $serotype == *:*:* ]]; then
    Scripts/MOST/MOST.py -1 $sample_r1 -2 $sample_r2 -st $mlst_data_dir -o $output_dir -serotype True
else
    echo "SeqSero2 predicted serotype. No need to run MOST for sample ${sample_name}"
fi

