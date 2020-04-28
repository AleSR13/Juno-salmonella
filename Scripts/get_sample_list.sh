#!/bin/bash/

#Create list of samples
sample_list=(`ls ./Samples | grep "_R1.*"`)

for i in "${!sample_list[@]}"; do
	sample_name=${sample_list[i]%_R1*}
	sample_list[$i]=`echo $sample_name`
done

echo ${sample_list[@]} > Samples/sample_list.txt
