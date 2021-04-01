## Overview #
Here we present the use of Divisive Amplicon Denoising Algorithm 2 (DADA2) pipeline for 16s rRNA data analysis.
This pipeline flow allows for inference of true biological sequences from reads.
The datasets used were 16S rRNA amplicon sequencing data from (input sample names).

## Preprocessing ##
Quality of the reads was analyzed using FastQC and it revealed that majority of the reads were of poor seqence quality.
The subsequent MultiQC report revealed that there the first 40 bases of most reads had a low Phred score which could have been attributed to the high percentage
N-count at the start of the reads.
Primer metadata also indicated the barcode sequences and reverse primers that were still present in the reads and could have contributed to the low quality reported.
Moreover, high adapter content characterized the end of the reads.
These details informed the trimming procedure that was performed on DADA2. 
Trimming parameters were set to retain ~ 250 bp forward reads and 180bp reverse reads. Using the barcode and reverse primer metadata, the first 25 and last
25 nucleotides were trimmed as well so as to remain with the true reads. 
Approximately 12.6% of the reads were lost after trimming.
Quality profiles were then plotted which confirmed an significant improve in quality hence the reads proceeded to further downstream processing.

## Learning Error Rates ##
DADA2 allows for error modelling using a machine-learning based algorithm and this was utilized to establish sequencing error rates which may include substitutions
such as Single Nucleotide Polymorphisms. 
Error rate plots revealed a decrease in error rates with an increase in sequence quality which was a satisfactory observation that validated the estimated error
rates, that is, the estimated error rate was similar to the observed error rate.


## Dereplication ##
Dereplication involved retrieving unique sequences from all the identical sequence reads which serves to reduce redundancy and computation time needed for analysis.
New quality scores were assigned to the unique sequences which is a functionality of the dereplication process.

## Sample Inference #
Sample inference was performed in order to obtain sequence variants from the dereplicated sequences using the core sample inference algorithm supported by DADA2.
The multithreading parameter was set to true since the process is heavy and takes up a lot of computing resources.


## Merging ##
Merging of the forward and reverse paired reads was carried out using the default minOverlap of 20 and setting the trimOverhang parameter to true as overhangs
were not trimmed earlier in the pipeline.
The parameters were choosen to facilitate optimal merging without decrease in quality.
Most of the reads were merged together, only having 1.9%  of the reads not merged.


## Constructing sequence table ##
A sequence table is a matrix with rows corresponding to (and named by) the samples, and columns corresponding to (and named by) the sequence variants.
From the table 10603 ASVs were inferred. 
The lengths of the merged sequences had most of them fall in the same range although in some samples there was significant change.

## Removing chimeras ##
Chimeric sequences are identified if they can be exactly reconstructed by combining a left-segment and a right-segment from two more abundant “parent” sequences.
The removeBimeraDenovo function was used where sequence variants identified as bimeric are removed and bimera free collection of unique sequences is returned.
To minimize on time taken, multithreading was set to true.
95.8% of the reads were retained.

## Tracking reads through the pipeline
A mean of 78.7% of the reads were retained across all the processing steps of the pipeline.

## Assigning Taxonomy
