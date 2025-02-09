#!/bin/bash
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"

cd ${DIR}

# Sanity checks
if [ ! -z "${1}" ] || [ ! -z "${2}" ]
then
    INPUTDIR="${1}"
    OUTPUTDIR="${2}"
else
    echo "no inputdir or outputdir(param 1, 2)"
    exit 1
fi

if [ ! -d "${INPUTDIR}" ] || [ ! -d "${OUTPUTDIR}" ] || [ ! -d "${INPUTDIR}/clean_fastq" ]
then
    echo "input dir $INPUTDIR, output dir $OUTPUTDIR or clean_fastq dir ${INPUTDIR}/clean_fastq does not exists"
    exit 1
fi

./juno-salmonella -y -i "${INPUTDIR}/clean_fastq" -o "${OUTPUTDIR}"
