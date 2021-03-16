/*

Enable DSL 2 syntax

*/

nextflow.enable.dsl = 2


/*

Process 3: Chimera Detection --Tool: usearch

*/

process CHIMERA_DETECTION {
    publishDir "$outdir/chimera", mode: 'copy'

    input:
        merged_reads
        reference_db
        merged_reads_dir

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

    usearch -orient $merged_reads_dir -db $reference_db \
    -fastqout oriented.fastq -tabbedout orient.txt

    usearch -fastq_filter oriented_fastq fastq_maxee 1.0 -fastaout filtered.fastq

    usearch -fastx_uniques filtered.fastq -fastaout uniques.fastq -sizeout -relabel Uniq

    usearch -cluster_otus uniques.fastq -otus otus.fastq -uparseout uparse.txt -relabel Otu

    usearch -unoise3 uniques.fastq -zotus zotus.fastq

    usearch -otutab merged_reads -otus otus.fastq -otutabout otutab.txt -mapout map.txt

    usearch -otutab merged_reads -zotus zotus.fastq -otutabout zotutab.txt -mapout zmap.txt
    """

}
