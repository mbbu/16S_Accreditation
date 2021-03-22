#! /usr/bin/env nextflow

//Enable DSL 2 syntax
nextflow.enable.dsl = 2

//Import modules here

include { FASTQC; TRIMMOMATIC; POST_FASTQC } from "./modules/qc.nf" addParams(outdir: "${params.outdir}")
include { USEARCH_MERGE; CHIMERA_DETECTION; REFERENCE_DB } from "./modules/chimeras.nf" addParams(outdir: "${params.outdir}")
include { OTU_CONVERSION; MAFFT_ALIGNMENT; MASKING; PHYLOGENY; MIDPOINT_ROOTING; OTUTABLE_TO_ARTIFACT;
          FEATURE_TABLE} from './modules/artifacts.nf' addParams(outdir: "${params.outdir}")
include { INTRO_DIVERSITY; ALPHA_DIVERSITY; SHANNON_DIVERSITY ; BETA_DIVERSITY }from './modules/visualization.nf'


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

    //VISUALIZATION

    // step 0: Intro_diversity
    medata_ch = Channel.fromPath(params.metadata)
    INTRO_DIVERSITY(FEATURE_TABLE.out.combine(medata_ch)

    // step 1: Alpha diversity
    mdata_ch = Channel.fromPath(params.metadata)
    ALPHA_DIVERSITY(INTRO_DIVERSITY.out.combine(mdata_ch))

    // step2: Shannon diversity
    metad_ch = Channel.fromPath(params.metadata)
    SHANNON_DIVERSITY(INTRO_DIVERSITY.out.combine(metad_ch))

    // step3: Beta diversity
    data_ch = Channel.fromPath(params.metadata)
    BETA_DIVERSITY(INTRO_DIVERSITY.out.combine(data_ch))
}
