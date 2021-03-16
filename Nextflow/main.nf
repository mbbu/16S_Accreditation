#! /usr/bin/env nextflow

/*
Enable DSL 2 syntax
*/

nextflow.enable.dsl = 2

/*

Define default parameters

*/
params.reads = "/home/festo/Documents/test_data/*_R{1,2}.fastq.gz"
params.outdir = "Results"

/*

Import modules here

*/

include {
    FASTQC;
    TRIMMOMATIC
} from "./modules/qc.nf"

include {
    CHIMERA_DETECTION;
} from "./modules/chimeras.nf"



Channel
    .fromFilePairs( params.reads, checkExists:true )
    .set{ read_pairs_ch }


/*

Declare the main pipepline below:

*/

workflow{
    // process 1a
    FASTQC(read_pairs_ch, params.outdir)
    // process 1b
    TRIMMOMATIC(read_pairs_ch, params.outdir)
    //process 3
    CHIMERA_DETECTION(params.outdir)
}
