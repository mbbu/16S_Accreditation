// Enable DSL 2 syntax
nextflow.enable.dsl = 2


// Process 3b: Reference_db --Tool: wget

process REFERENCE_DB{
    publishDir path: { "${params.outdir}/database" }

    output:
    path 'reference_db/silva.bacteria.fasta', emit: reference_db

    script:
    """
    wget https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.bacteria.zip
    unzip silva.bacteria.zip
    mv silva.bacteria reference_db
    """
}

// Process 3c: Chimera Detection --Tool: usearch

process CHIMERA_DETECTION {
    publishDir "$outdir/chimera", mode: 'copy'

    input:
        path merged_reads
        path reference_db

    output:
        path 'chimera_out.fastq', emit: chimera_out_fastq
        path 'oriented.fastq', emit: oriented_fastq
        path 'oriented.txt', emit: oriented_txt
        path 'filtered.fastq', emit: filtered_fastq
        path 'uniques.fastq', emit: uniques_fastq
        path 'otus.fastq', emit: otus_fastq
        path 'uparse.txt', emit: uparse_txt
        path 'zotus.fastq', emit: zotus_fastq
        path 'otutab.txt', emit: otutab_txt
        path 'map.txt', emit: map_txt
        path 'zotutab.txt', emit: zotutab_txt
        path 'zmap.txt', emit: zmap_txt

    script:
    """
    usearch -uchime2_ref $merged_reads -db $reference_db \
    -uchimeout chimera_out.fastq -strand plus -mode sensitive

    usearch -orient $merged_reads -db $reference_db \
    -fastqout oriented.fastq -tabbedout orient.txt

    usearch -fastq_filter oriented.fastq fastq_maxee 1.0 -fastqout filtered.fastq

    usearch -fastx_uniques filtered.fastq -fastqout uniques.fastq -sizeout -relabel Uniq

    usearch -cluster_otus uniques.fastq -otus otus.fastq -uparseout uparse.txt -relabel Otu

    usearch -unoise3 uniques.fastq -zotus zotus.fastq

    usearch -otutab $merged_reads -otus otus.fastq -otutabout otutab.txt -mapout map.txt

    usearch -otutab $merged_reads -zotus zotus.fastq -otutabout zotutab.txt -mapout zmap.txt
    """

}
