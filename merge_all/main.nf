#! /usr/bin/env nextflow

//Enable DSL 2 syntax

nextflow.enable.dsl = 2

//Import Modules

include {OTU_conversion; MAFFT_alignment; Masking; Phylogenetic_Tree; Midpoint_root; OTUtable_to_QiimeArtifact; Feature_Table}from 'modules/nextflow.nf'

include { FASTQC; TRIMMOMATIC; POST_FASTQC } from "/modules/qc.nf"

include { CHIMERA_DETECTION; REFERENCE_DB } from "/modules/chimeras.nf"


params.reads = "/home/festo/Documents/test_data/*_R{1,2}.fastq.gz"
params.outdir = "Results"

//Run the main workflow below:

workflow{
	Channel
    		.fromFilePairs( params.reads, checkExists:true )
    		.set{ read_pairs_ch }
	// process 1a
    	FASTQC(read_pairs_ch)
	
	// process 1b
	TRIMMOMATIC(read_pairs_ch)

	// process 1c
	POST_FASTQC(TRIMMOMATIC.out)

	// process 3a Get Reference DB
	REFERENCE_DB

	// process 3b
    	CHIMERA_DETECTION(params.outdir, REFERENCE_DB.out)
}


workflow {
        // step 1
        input_ch = channel.fromPath(params.otufastq)
        OTU_conversion(input_ch)

        // step 2
        MAFFT_alignment(OTU_conversion.out)

        // step 3
        Masking(MAFFT_alignment.out)

        // step 4
        Phylogenetic_Tree(Masking.out)

        // step 5
        Midpoint_root(Phylogenetic_Tree.out)

        // step 6
        inp_ch = channel.fromPath(params.otu_txt)

        //step 7
         Feature_Table(OTUtable_to_QiimeArtifact.out)
}





