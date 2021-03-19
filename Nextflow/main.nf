#! /usr/bin/env nextflow

//Enable DSL 2 syntax

nextflow.enable.dsl = 2

//Define default parameters
//TODO: Move params to config file when done

params.reads = "/home/festo/Documents/test_data/*_R{1,2}.fastq.gz"
params.outdir = "Results"

//Import modules here

include { FASTQC; TRIMMOMATIC; POST_FASTQC } from "./modules/qc.nf" addParams(outdir: "${params.outdir}")
include { CHIMERA_DETECTION; REFERENCE_DB } from "./modules/chimeras.nf"

// Set the channel for the inputs
Channel
    .fromFilePairs( params.reads, checkExists:true )
    .set{ read_pairs_ch }

//Run the main workflow below:

workflow{
    // process 1a
    //FASTQC(read_pairs_ch)
    // process 1b
    TRIMMOMATIC(read_pairs_ch)
    // process 1c
    POST_FASTQC(TRIMMOMATIC.out)
    //process 3a merge reads
    USEARCH_MERGE(TRIMMOMATIC.out.collect())
    // process 3a Get Reference DB
    //TODO: move database as an input parameter
    REFERENCE_DB()
    // process 3b
    CHIMERA_DETECTION(USEARCH_MERGE.out, REFERENCE_DB.out)
}
