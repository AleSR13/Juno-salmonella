#!/bin/bash/

#Create list with sample names
sample_list=(`ls ./Samples | grep "_R1"`)
suffix_list=(`ls ./Samples | grep "_R1"`)

for i in "${!sample_list[@]}"; do
        filename=$(basename -- "${sample_list[i]}")
        filename="${filename%_R1*}"
        sample_list[$i]=`echo $filename`
        suffix=$(basename -- "${suffix_list[i]}")
        suffix="${suffix##*_R}"
        suffix_list[$i]=`echo $suffix`
done

echo ${sample_list[@]} > Samples/sample_list.txt
echo ${suffix_list[@]} > Samples/suffix_list.txt
