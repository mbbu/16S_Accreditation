<img src="https://avatars.githubusercontent.com/u/49394656?s=200&v=4"/>

<!-- [![](https://img.shields.io/badge/left-right-f39f37)](#) -->
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A520.10.0-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![](https://img.shields.io/badge/contributors-9-f39f37)](https://github.com/mbbu/16S_Accreditation/graphs/contributors)
[![](https://img.shields.io/badge/build-passing-f39f37labelColor=brightgreen)](#)
# Introduction
This pipeline is for analysis of 16s rRNA
# Pipeline Summary
This pipeline performs the following in order:
1. Quality check of raw reads
2. Trimming of adapters from reads
3. Merging/Stitching
4. Filtering and Primer removal
5. Orientation
6. Dereplication
7. Chimera detection
8. Clustering OTUs
9. Phylogeny
10. Taxonomy
11. Alpha diversity and Beta diversity
# Quick Start
  1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation)(`>21.11.3`)
  2. Install [`Trimmomatic`](http://www.usadellab.org/cms/?page=trimmomatic)(`>V0.39`), [`qiime2`](https://docs.qiime2.org/2021.11/install/)(`>V2020.6`), [`multiqc`](https://multiqc.info/)(`>V1.4`), [`vsearch`](https://github.com/torognes/vsearch)(`>V2.16.0`)
  3. Download the pipeline into your directory with the command
     ```
     git clone git@github.com:mbbu/16S_Accreditation.git
     ```
  4. Test on the given test data with the command 
      ```
      nextflow -C test.config run main.nf
      ```
  5. Start running your own analysis
     ```
     nextflow run main.nf --primers primers.txt --metadata metadata.tsv --reads microbiome-data/*_R{1,2}.fastq.gz
     ```
# Credits
Check this [contributors page](https://github.com/mbbu/16S_Accreditation/graphs/contributors) for collaborators. All are listed in the report, including those who did not commit to GitHub. 
