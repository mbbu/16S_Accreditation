// Enable DSL2

nextflow.enable.dsl= 2

//Merge the reads

process USEARCH_MERGE {
    publishDir path: { "${params.outdir}/merge" }
    tag "Merging reads"

    input:
    path (fastq)

    output:
    path "all_reads_merged.fastq", emit : merged_reads
    path "merge.log", emit : merge_log

    script:
    """
    mkdir -p u_merge
    cp ${fastq}* u_merge/. && cd u_merge
    # Test to find the limit to use for merging
    usearch -fastq_mergepairs *_R1.paired.fastq -relabel @ -report ../merge.log
    # Extract the limits
    low_lim=`grep "Min" ../merge.log | grep -o "[0-9]\\+"`
    high_lim=`grep "Max" ../merge.log | grep -o "[0-9]\\+"`
    # Merge the Forward and Reverse
    usearch -fastq_mergepairs *_R1.paired.fastq -relabel @ \
    -fastq_maxdiffs 10 -fastq_pctid 10 \
    -fastq_minmergelen \$low_lim -fastq_maxmergelen \$high_lim \
    -fastqout ../all_reads_merged.fastq
    # Clean up
    cd .. && rm -rf u_merge

    """
}

// Filter and primer removal
process FILTER {
    publishDir path: "${params.outdir}/filter", mode: 'copy'

    input:
    path all_reads_merged_fq
    path primer_ch

    output:
    path "filtered.fasta", emit : filtered_fasta
    path "filter.log", emit: filter_log

    script:
    filtered = 'filtered.fasta'
    filtlog = 'filter.log'

    """
    #sub_sample reads
    #usearch -fastx_subsample ${all_reads_merged_fq} -sample_size 1000 -fastqout all_sub_primercheckU.fq

    #creating a primer fastafile
    #echo ">forward_primer" >> Primers.fasta && cut -f3 ${primer_ch} | grep '^N' | uniq >> Primers.fasta
    #echo ">reverse_primer" >> Primers.fasta && cut -f4 ${primer_ch} | grep '^N' | uniq >> Primers.fasta

    #searching the reads for primers
    #usearch -search_oligodb all_sub_primercheckU.fq -db Primers.fasta \
    #-strand both -userout Uprimer_hits.txt \
    #-userfields query+qlo+qhi+qstrand

    #filtering primers using max quality score 75 for illimina
    vsearch -fastq_filter ${all_reads_merged_fq} --fastq_maxee 1.0 \
    --fastq_stripleft 24 --fastq_stripright 25 \
    --fastq_qmax 75 --fastaout ${filtered} \
    --log ${filtlog}
    """
}

// Downloading reference_db

process REFERENCEDB {
      publishDir path: "${params.outdir}/Rdb", mode: 'copy'

      output:
      path 'reference_db/silva.gold.ng.fasta', emit: reference_db

      script:
      """
      wget https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.bacteria.zip
      unzip silva.bacteria.zip
      mv silva.bacteria reference_db

      """

}

//orient

process ORIENT {
    publishDir path: "${params.outdir}/orient", mode: 'copy'

    input:
    path filt_fasta
    path refe_db

    output:
    path 'orient.fasta', emit: orient_fasta
    path 'notmatched.fasta', emit: notmatched_fasta
    path 'orient.txt', emit: orient_txt
    path 'orient.log', emit: orient_log

    script:
    match = "orient.fasta"
    notmatch = "notmatched.fasta"
    oritab = "orient.txt"
    orilog = "orient.log"

    """
    vsearch -orient ${filt_fasta} --db ${refe_db} \
    --fastaout ${match} --notmatched ${notmatch} \
    --tabbedout ${oritab} --log ${orilog}
    """
}

//dereplication

process DEREPLICATION {
    publishDir path: "${params.outdir}/dereps", mode: 'copy'

    input:
    path orient_fa

    output:
    path 'uniqs.fasta', emit: uniqs_fasta
    path 'uniqs.log', emit: uniqs_log

    script:
    uniq = "uniqs.fasta"
    uniqlog = "uniqs.log"

    """
    vsearch --derep_fulllength ${orient_fa} --strand plus \
    --output ${uniq} --sizeout --relabel Uniq --log ${uniqlog}
    """
}

// chimera_detection and removal

process CHIMERA_DETECTION {
    publishDir path: "${params.outdir}/chimeras", mode: 'copy'

    input:
    path uniqs_fa
    path ref_db

    output:
    path 'chime.txt', emit: chime_txt
    path 'chimeras.fasta', emit: chimeras_fasta
    path 'notchimeras.fasta', emit: notchimeras_fasta
    path 'chime.log', emit: chime_log

    script:
    chimetxt = "chime.txt"
    chimes = "chimeras.fasta"
    notchimes = "notchimeras.fasta"
    chimelog = "chime.log"

    """
    vsearch --uchime_ref ${uniqs_fa} --db ${ref_db} \
    --sizein --uchimeout ${chimetxt} --chimeras ${chimes} \
    --nonchimeras ${notchimes} --relabel notchime \
    --sizeout --log ${chimelog}

    """
}

//clustering

process CLUSTER_OTUS {
      publishDir path: "${params.outdir}/otus", mode: 'copy'

      input:
      path uniq_fa

      output:
      path 'otus.fasta', emit: otus_fasta
      path 'otu.log', emit: otu_log
      path 'ASVs.fasta', emit: asvs_fasta
      path 'ASV.log', emit: asvs_log
      path 'otutab.txt', emit: otutab_txt
      path 'ASVtab.txt', emit: asvtab_txt
      path 'otutab.json', emit: otutab_json
      path 'ASVtab.json', emit: asvtab_json

      script:
      centroids = "otus.fasta"
      otulog = "otu.log"
      asv = "ASVs.fasta"
      asvlog = "ASV.log"
      otutab = "otutab.txt"
      otubiom = "otutab.json"
      asvtab = "ASVtab.txt"
      asvbiom = "ASVtab.json"

      """
      vsearch --cluster_size ${uniq_fa}  --id 0.97 --strand plus \
      --centroids ${centroids} --relabel Otus \
      --log ${otulog} --otutabout ${otutab} --biomout ${otubiom}

      vsearch --cluster_unoise ${uniq_fa} --strand plus \
      --centroids ${asv} --relabel ASVs --sizeout \
      --log ${asvlog} --otutabout ${asvtab} --biomout ${asvbiom}

      """

}

process CLUSTER_OTUS_U {
      publishDir path: "${params.outdir}/otus", mode: 'copy'

      input:
      path (uniq_fa)
      path (qced_fa)

      output:
      path "ASVs.fasta" , emit: otus_fasta
      path "ASV_counts.txt", emit: otutab_txt
      script:
      """
      usearch -unoise3 ${uniq_fa} -zotus ASVs.fasta -minsize 9

      # get stats
      sed -i 's/Zotu/ASV_/' ASVs.fasta
      vsearch -usearch_global ${qced_fa} --db ASVs.fasta --id 0.99 --otutabout ASV_counts.txt
      """
}
