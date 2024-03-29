//Enable DSL 2 syntax

nextflow.enable.dsl = 2

//Process 1a: Quality check --Tool: fastqc

process FASTQC {
    publishDir path: { "${params.outdir}/fastqc_raw" }
    tag "Quality checking raw reads"

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

process MultiQC_raw{
    publishDir path: { "${params.outdir}/multiqc_raw" }
    tag "Generating raw multiQC report"

    input:
        file(fastqc_out)

    output:
        file('multiqc_report.html')

    """
    multiqc .
    """
}

//Process 1b: Trimming --Tool: trimmomatic

process TRIMMOMATIC {
    publishDir path: { "${params.outdir}/trimming" }
    tag "Trimming raw reads"

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

// Process 1c: Post trimming QC
process POST_FASTQC {
    publishDir path: { "${params.outdir}/fastqc_post" }
    tag "Quality check trimmed reads"

    input:
    tuple path(read_R1), path(read_R2)

    output:
    path "${sample_id}_logs"

    script:
    sample_id = ( read_R1 =~ /(.+)_R1.paired.fastq/ )[0][1]
    """
    mkdir ${sample_id}_logs
    fastqc -o ${sample_id}_logs -f fastq -q ${read_R1} ${read_R2}
    """
}

process Post_MultiQC{
    publishDir path: { "${params.outdir}/multiqc_postfastqc" }
    tag "Generating post fastqc, multiQC report"

    input:
        file(fastqc_out)

    output:
        file('multiqc_report.html')

    """
    multiqc .
    """
}
