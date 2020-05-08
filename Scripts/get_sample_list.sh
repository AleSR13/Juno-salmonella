#!/bin/bash/

#Create list with sample names
suffix_list=(`ls ./Samples | grep "_R1.*"`)
sample_list=(`ls ./Samples | grep "_R1.*"`)

for i in "${!suffix_list[@]}"; do
        filename=$(basename -- "${suffix_list[i]}")
        extension="${filename##*R1.}"
        suffix_list[$i]=`echo $extension`
        filename="${filename%_R1*}"
        sample_list[$i]=`echo $filename`
done

echo ${sample_list[@]} > Samples/sample_list.txt
echo ${suffix_list[@]} > Samples/suffix_list.txt
