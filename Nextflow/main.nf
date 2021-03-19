#! /usr/bin/env nextflow

//Enable DSL 2 syntax

nextflow.enable.dsl = 2

//Import modules here

include { FASTQC; TRIMMOMATIC; POST_FASTQC } from "./modules/qc.nf" addParams(outdir: "${params.outdir}")
include { USEARCH_MERGE; CHIMERA_DETECTION; REFERENCE_DB } from "./modules/chimeras.nf"
include {OTU_conversion; MAFFT_alignment; Masking; Phylogenetic_Tree; Midpoint_root; OTUtable_to_QiimeArtifact; Feature_Table}from './modules/artifacts.nf' 
include { alpha_diversity; shannon_diversity ; beta_diversity }from './modules/visualization'

//Run the main workflow below:

workflow{
    // PART ONE
    //PREPROCESSING
    Channel.fromFilePairs( params.reads, checkExists:true ).set{ read_pairs_ch }
    
    // process 1a
    FASTQC(read_pairs_ch)
    // process 1b
    TRIMMOMATIC(read_pairs_ch)
    // process 1c
    POST_FASTQC(TRIMMOMATIC.out)
    //process 3a merge reads
    
    // PART TWO
    USEARCH_MERGE(TRIMMOMATIC.out.collect())
    // process 3a Get Reference DB
    //TODO: move database as an input parameter
    REFERENCE_DB()
    // process 3b
    
    //PART THREE
    CHIMERA_DETECTION(USEARCH_MERGE.out, REFERENCE_DB.out)
    
    // PART FOUR
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
    OTUtable_to_QiimeArtifact(inp_ch)
    //step 7
    Feature_Table(OTUtable_to_QiimeArtifact.out)	
    
    // PART FIVE
    // DATA VISUALIZATION
    // step 1: Alpha diversity
    al_vector_ch = Channel.fromPath(params.evennessvector)
    mdata_ch = Channel.fromPath(params.metadata)
    alpha_out_ch = al_vector_ch.combine(mdata_ch)
    alpha_diversity(alpha_out_ch)

     // step2: Shannon diversity
     sh_vector_ch = Channel.fromPath(params.shannonvector)
     metad_ch = Channel.fromPath(params.metadata)
     shannon_out_ch = sh_vector_ch.combine(metad_ch)
     
     // step3: Beta diversity 
     bt_vector_ch = Channel.fromPath(params.betavector)
     data_ch = Channel.fromPath(params.metadata)
     beta_out_ch = bt_vector_ch.combine(data_ch)
     beta_diversity(beta_out_ch)
     

}
