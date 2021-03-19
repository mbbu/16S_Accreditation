#!/opt/apps/nextflow/20.10.0/bin/nextflow

// Enabling DSL 2 Syntax

nextflow.enable.dsl = 2

// Module file for data visualization

//Process1 - Alpha diversity analysis using eveness vector

process Alpha_Diversity_Eveness {
    tag "Running Alpha_Diversity_Eveness:"
    
    publishDir "$params.outdir"
    
    input:
  	tuple val(vector), file(metadata)
    
    output:
    	file(alpha_evenness)
    
    script:

    	alpha_evenness = "evenness-group-significance.qzv"

     	"""
    		qiime diversity alpha-group-significance --i-alpha-diversity ${vector} --m-metadata-file ${metadata} --o-visualization ${alpha_evenness}
     
     	"""
}

//Process2 - Alpha diversiy analysis using shannon vector

process Alpha_Diversity_Shannon {
    tag "Running_Alpha_Diversity_Shannon:"
    
    publishDir "$params.outdir"
    
    input:
    	tuple val(vector), file(mdata)
    
    output:
    	file(alpha_shannon)
    
    script:

    alpha_shannon = "shannon-group-significance.qzv"

     """
   	 qiime diversity alpha-group-significance \
     	--i-alpha-diversity ${vector} \
     	--m-metadata-file ${mdata} \
     	--o-visualization ${alpha_shannon}
     
     """
}

//Process 3 - Beta Diversity

process Beta_Diversity {
    tag "Running_Beta_Diversity:"
    
    publishDir "$params.outdir"
    
    input:
    	tuple val(vector), file(metdata)
    
    output:
    	file(beta_div)
    
    script:

    beta_div = "bray_curtis_pcoa_results.qzv"

    """
     	qiime emperor plot \
      	--i-pcoa ${vector}\
      	--m-metadata-file ${metdata}\
      	--o-visualization ${beta_div}
      
    """  
      
}      
      
      
      
      
            
          
