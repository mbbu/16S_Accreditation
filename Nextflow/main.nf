#! /usr/bin/env nextflow

//Enable DSL 2 syntax
nextflow.enable.dsl = 2

//Import modules here

include { FASTQC; TRIMMOMATIC; POST_FASTQC } from "./modules/qc.nf" addParams(outdir: "${params.outdir}")
include { USEARCH_MERGE; CHIMERA_DETECTION; REFERENCE_DB } from "./modules/chimeras.nf" addParams(outdir: "${params.outdir}")
include { OTU_CONVERSION; MAFFT_ALIGNMENT; MASKING; PHYLOGENY; MIDPOINT_ROOTING; OTUTABLE_TO_ARTIFACT;
          FEATURE_TABLE} from './modules/artifacts.nf' addParams(outdir: "${params.outdir}")
//include { alpha_diversity; shannon_diversity ; beta_diversity }from './modules/visualization.nf'


// set the reads channel
Channel
    .fromFilePairs( params.reads, checkExists:true )
    .set{ read_pairs_ch }

//Run the main workflow below:
workflow{
    // Quality check and trimming
    // process 1a
    FASTQC(read_pairs_ch)
    // process 1b
    TRIMMOMATIC(read_pairs_ch)
    // process 1c
    //POST_FASTQC(TRIMMOMATIC.out)
    
    // process 2 merge reads
    USEARCH_MERGE(TRIMMOMATIC.out.collect())
    // process 3a Get Reference DB
    //TODO: move database as an input parameter
    REFERENCE_DB()
    // process 3b
    CHIMERA_DETECTION(USEARCH_MERGE.out, REFERENCE_DB.out)

    // Qiime2 artefact
    // step 1
    OTU_CONVERSION(CHIMERA_DETECTION.out.otus_fastq)
    // step 2
    MAFFT_ALIGNMENT(OTU_CONVERSION.out)
    // step 3
    MASKING(MAFFT_ALIGNMENT.out)
    // step 4
    PHYLOGENY(MASKING.out)
    // step 5
    MIDPOINT_ROOTING(PHYLOGENY.out)
    // step 6
    OTUTABLE_TO_ARTIFACT(CHIMERA_DETECTION.out.otutab_txt)
    //step 7
    FEATURE_TABLE(OTUTABLE_TO_ARTIFACT.out)

    // PART FIVE
    // DATA VISUALIZATION
    // step 1: Alpha diversity
    //al_vector_ch = Channel.fromPath(params.evennessvector)
    //mdata_ch = Channel.fromPath(params.metadata)
    //alpha_out_ch = al_vector_ch.combine(mdata_ch)
    //alpha_diversity(alpha_out_ch)

     // step2: Shannon diversity
     //sh_vector_ch = Channel.fromPath(params.shannonvector)
     //metad_ch = Channel.fromPath(params.metadata)
     //shannon_out_ch = sh_vector_ch.combine(metad_ch)

     // step3: Beta diversity
     //bt_vector_ch = Channel.fromPath(params.betavector)
     //data_ch = Channel.fromPath(params.metadata)
     //beta_out_ch = bt_vector_ch.combine(data_ch)
     //beta_diversity(beta_out_ch)


}
