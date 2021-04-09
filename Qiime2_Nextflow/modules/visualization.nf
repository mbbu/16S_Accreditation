#!/home/nanjala/miniconda3/envs/qiime2-2020.8/bin/nextflow

process INTRO_DIVERSITY {
  tag "Introduction to diversity"
  publishDir path: { "${params.outdir}/visualization" }

  input:
    tuple val(otu_tab), file(medata)
  output:
    file(otu_out)
    path(pcoa)
  script:
  otu_out = "core-metrics-results"
  pcoa = "pcoa-visualization.qzv"
    """
    qiime diversity core-metrics --i-table ${otu_tab} --p-sampling-depth 4000 --m-metadata-file ${medata} --output-dir ${otu_out}

    # Pcoa plot
    qiime emperor plot --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
    --m-metadata-file ${medata} --o-visualization pcoa-visualization.qzv
    """
}

process ALPHA_DIVERSITY {
  tag " evaluate alpha_diversity"
  publishDir path: { "${params.outdir}/visualization" }

  input:
    tuple val(vector), file(mdata)
  output:
    file(alpha_out)
  script:
    alpha_out = "evenness-group-significance.qzv"
    """
      #Alpha Diversity
      #Evenness
      qiime diversity alpha-group-significance --i-alpha-diversity ${vector}/evenness_vector.qza --m-metadata-file ${mdata} --o-visualization ${alpha_out}

    """
}


process SHANNON_DIVERSITY {
  tag "evaluate shannon_diversity"
  publishDir path: { "${params.outdir}/visualization" }

  input:
    tuple val(shvector), file(shmdata)
  output:
    file(shannon_out)
  script:
    shannon_out = "shannon_group-significance.qzv"
    """
      #Shannon vector
      qiime diversity alpha-group-significance \
	--i-alpha-diversity ${shvector}/shannon_vector.qza --m-metadata-file ${shmdata} --o-visualization ${shannon_out}
    """
}

process BETA_DIVERSITY {
  tag "evaluate beta_diversity"
  publishDir path: { "${params.outdir}/visualization" }

  input:
    tuple val(btvector), file(btmdata)
  output:
    file(beta_out)
  script:
    beta_out = "bray_curtis_pcoa_results.qzv"
    """
      #Beta Diversity
      #Bray_Curtis

      qiime emperor plot --i-pcoa ${btvector}/bray_curtis_pcoa_results.qza --m-metadata-file ${btmdata} --o-visualization ${beta_out}

    """
}

process TAXONOMIC_BARPLOT {
    tag "generate taxonomic barplot"
    publishDir path: { "${params.outdir}/visualization" }

    input:
    path otus_qza
    path otutab_qza
    path classifier_qza
    path medata_ch

    output:
    path "taxonomy.qza", emit: taxonomy_qza
    path "taxonomy.qzv", emit: taxonomy_qzv
    path "taxabarplots.qzv", emit: taxabarplots_qzv

    script:
    taxonomyq = "taxonomy.qza"
    taxonomyv = "taxonomy.qzv"
    taxabar = "taxabarplots.qzv"

    """
    qiime feature-classifier classify-sklearn --i-reads ${otus_qza} --i-classifier ${classifier_qza} --o-classification ${taxonomyq}

    qiime metadata tabulate --m-input-file ${taxonomyq} --o-visualization ${taxonomyv}

    qiime taxa barplot --i-table ${otutab_qza} --i-taxonomy ${taxonomyq} --m-metadata-file ${medata_ch} --o-visualization ${taxabar}

    """
}

// TODO Add rarefaction process the code is below
//qiime diversity alpha-rarefaction \
//--i-table ../artifacts/otu_tab.qza \
//--i-phylogeny ../artifacts/rooted_tree.qza \
//--p-max-depth 4000 \ #The max depth should be parsed from the feature table
//--m-metadata-file ../set5_meta.txt \
//--o-visualization rarefaction_4000.qzv
