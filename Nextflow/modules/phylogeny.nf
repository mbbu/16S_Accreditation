#!/opt/apps/nextflow/20.10.0/bin/nextflow

//Enabling DSL 2 syntax

nextflow.enable.dsl = 2


// Module for Phylogeny and Diversity Analysis

// Process 1 - Converting OTU Reads into Qiime2 artifact

process convertOTU {
    tag "Converting OTUs:"

    publishDir "$params.outdir"
    
    input:
    file(otus)
    
    output:
    file("otus.qza")
    
    script:
    
        out_otus = "otus.qza"
     
        """
        qiime tools import --input-path ${otus} --output-path ${out_otus} --type 'FeatureData[Sequence]'
      
        """
}


// Process 2 - Alignment using Mafft

process Alignment {
    tag "Running Alignment:"
    
    publishDir "$params.outdir"
    
    input:
    file (output_otus)
    
    output:
    file ("aligned_otus.qza")
    
    script:
    
        aligned = "aligned_otus.qza"
    
        """
        qiime alignment mafft --i-sequences ${output_otus} --o-alignment ${aligned}
        
        """
        
}        
    
    
// Process 3 - Making phylogenetically relevant sites

process makingSites {
    tag "Making sites:"
    
    publishDir "$params.outdir"
    
    input:
    file(aligned_otus)
    
    output:
    file("masked_aligned_otus.qza")
    
    script:
    
        masked_otus = "masked_aligned_otus.qza"
        
        """
        qiime alignment mask --i-alignment ${aligned_otus} --o-masked-alignment ${masked_otus}
        
        """
}


// Process 4 - Constructing phylogenetic tree

process phylogenTree {
    tag "Constructing phylogenetic tree:"
    
    publishDir = "$params.outdir"
    
    input:
    file(masked_out)
    
    output:
    file("unrooted_tree.qza")
    
    script:
    
        unroot_tree = "unrooted_tree.qza"
        
        """
        qiime phylogeny fasttree --i-alignment ${masked_out} --o-tree ${unroot_tree}
        
        """
}


// Process 5 - Midpoint-rooting of phylogenetic tree

process midpointRoot {
    tag "Midpoint-rooting phylogenetic tree:"
    
    publishDir "$params.outdir"
    
    input:
    file(unrootedtree)
    
    output:
    file("rooted-tree.qza")
    
    script:
    
        rooted = "rooted-tree.qza"
        
        """
        qiime phylogeny midpoint-root --i-tree ${unrootedtree} --o-rooted-tree ${rooted}
        
        """           
}


// Process 6 - Convert OTU Table to Qiime Artifact

process convertOTUTable {

    tag "Converting OTU Table:"
    
    publishDir "$params.outdir"
    
    input:
    file(otutable)
    
    output:
    file("otu_tab.qza")
    
    script:
    
        otu_table_biom = "otu_table.from_txt_hdf5.biom"
        otu_tab_out = "otu_tab.qza"
        """
        biom convert -i ${otutable} -o ${otu_table_biom} --table-type="OTU table" --to-hdf5
        qiime tools import --input-path ${otu_table_biom} --type 'FeatureTable[Frequency]' --output-path ${otu_tab_out}
        
        """
}


// Process 7 - Alpha and Beta Diversity Analysis

process Diversity {

    tag "Running Diversity:"
    
    publishDir "$params.outdir"
    
    input:
    file(OTUtab)
    
    
    script:
    
        metadatatsv = "practice.dataset1.metadata.tsv"
    
        """
        qiime diversity core-metrics --i-table ${OTUtab} --p-sampling-depth 4000 --m-metadata-file ${params.meta} --output-dir core-metrics-results
        
        """ 
} 

