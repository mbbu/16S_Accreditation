#! /usr/bin/env nextflow

nextflow.enable.dsl=2

params.reads = "/home/festo/Documents/test_data/*_R{1,2}.fastq.gz"
params.outdir = "Results"

Channel
    .fromFilePairs( params.reads, checkExists:true )
    .set{ read_pairs_ch }

process fastqc {
    publishDir "${params.outdir}/fastqc_raw"

    input:
    tuple val(sample_id), path(reads)

    output:
    path "${sample_id}_logs"

    script:
    """
    mkdir ${sample_id}_logs
    fastqc -o ${sample_id}_logs -f fastq -q ${reads}
    """
}

process trimmomatic {
    publishDir "${params.outdir}/trimming"

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple path(fq_1_paired), path(fq_2_paired)

    script:
    fq_1_paired = sample_id + '_R1.paired.fastq'
    fq_1_unpaired = sample_id + '_R1.unpaired.fastq'
    fq_2_paired = sample_id + '_R2.paired.fastq'
    fq_2_unpaired = sample_id + '_R2.unpaired.fastq'

    """
    trimmomatic \
    PE -phred33 \
    ${reads[0]} \
    ${reads[1]} \
    $fq_1_paired \
    $fq_1_unpaired \
    $fq_2_paired \
    $fq_2_unpaired \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    """
}

workflow {
  fastqc(read_pairs_ch)
  trimmomatic(read_pairs_ch)
}
