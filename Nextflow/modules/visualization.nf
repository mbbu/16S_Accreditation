#!/home/nanjala/miniconda3/envs/qiime2-2020.8/bin/nextflow

process INTRO_DIVERSITY {
  tag "Introduction to diversity"
  publishDir "$params.outdir"
  
  input:
    tuple val(otu_tab), file(medata)
  output:
    file(otu_out)
  script:
  otu_out = "core-metrics-results"
    """
    qiime diversity core-metrics --i-table ${otu_tab} --p-sampling-depth 4000 --m-metadata-file ${medata} --output-dir ${otu_out}
    
    """
}

process ALPHA_DIVERSITY {
  tag " evaluate alpha_diversity"
  publishDir "$params.outdir"

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
  publishDir "$params.outdir"

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
  publishDir "$params.outdir"

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
