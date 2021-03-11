#!/usr/bin/bash

BASEDIR=/data/accredetation/16S/test
mkdir $BASEDIR/Results/QC/

time fastqc -f fastq -o $BASEDIR/Results/QC/ -t 36 $BASEDIR/Data/set5/*.fastq
#real    2m56.175s
#user    31m24.230s
#sys     2m28.907s

# Create a directory for results in the GitHub Repo
mkdir $BASEDIR/Code/Results/MultiQC

cd $BASEDIR/Code/Results/MultiQC

time multiqc $BASEDIR/Results/QC/
#real    1m9.077s
#user    1m5.471s
#sys     0m14.860s


