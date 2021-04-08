# Nexflow Report

We developed a 16s workflow report utilizing the following tools:
- fastqc v0.11.9
- multiqc v1.4
- trimommatic v0.39
- usearch v11.0
- vsearch v2.16
- qiime env 2020.8
- Nextflow 20.10.0 (dsl 2)

Our analysis pipeline follows the following order:
1. Quality check of raw reads
2. Trimming of adapters from reads
3. Merging/Stitching
4. Filtering and Primer removal
5. Orientation
6. Dereplication
7. Chimera detection
8. Clustering OTUs
9. 

This workflow has been summarized in the Nextflow analysis figure below

![](./pipeline_info/pipeline_dag.png)

## Sample info
We had a total of 124 paired end reads samples. These samples had a length of 250bp.

## Runtime analysis
The total runtime of each process is summarized in this Nextflow [report](./pipeline_info/execution_timeline.html).
The timeline report shows the job wall time and memory used by each individual sample in the different steps. It also provides info on the total
time used to run the entire workflow.

A summary of this information is available in form if average time for each step, the percentage of CPUs used and memory in 
this [report](./pipeline_info/execution_report.html). 

The average storage used by the different steps is summarized below;

|Analysis Step | time |Storage |
| -------- | -------- | -------- |
| Quality Check (fastqc & multiqc) |      | 388M & 4.5M |
| Trimming | | 21G |
| Quality Check (fastqc & multiqc) |      | 388M & 4.5M |
| Merging (usearch) | | 14G |
| Filtering (vsearch) | | 4.6G |
| Orient (vsearch) | | 4.9G |
| Dereplication (vsearch) |  | 197M |
| Chimera detection (vsearch) | | 261M |
| Cluster OTUs (usearch) | | 792K |
| Reference DB | | 7.2M | 
| Artifacts and classifier | | 28M | 
| Visualization (qiime2) | | 6.1M |

# Quality check
The Quality of the read was checked using fastqc. The data was characterized by low per base sequence content, 
high sequence duplication and overrepresntation.

A summary for all the samples is can be seen in this [muiltiqc report](./figures/raw_multiqc_report.html)

# Trimming
Trimming was done using trimmomatic to remove sequencing adapters and low quality reads. The following parameters 
were used to improve the read quality:
	- phred score 33
	- min length 36
	- sliding window 4:15

# Post trimming quality check
A summary of the results post trimming is available in this [multiqc report](./figures/post_multiqc_report.html)

