 
/*
Process 4(i): Conversion of OTUS into Qiime2 Artifact
*/

process OTU_conversion {
	tag "OTU conversion"

	publishDir '$params.output_dir'

	input:
	file(otus)

	output:
	file(otus_conv)

	script:

	otus_conv = "otus.qza"

	"""
	qiime tools import --input-path ${otus} --output-path ${otus_conv} --type 'FeatureData[Sequence]'
	"""
}


/*
Process 4(ii): MAFFT alignment
*/

process MAFFT_alignment {
	tag "Running MAFFT_alignment"

	publishDir '$params.output_dir'

	input:
	file(otus_out)

	output:
	file(aligned)

	script:

	aligned = "aligned_otus.qza"

	"""
	qiime alignment mafft --i-sequences ${otus_out} --o-alignment ${aligned}

	"""
}

/*
Process 4(iii): Masking Aligned OTUS
*/

process Masking {

	tag " masking_aligned_otus"

	publishDir "$params.output_dir"

	input:
	file(aligned_otus)

	output:
	file(masked)

	script:

	masked = "masked_aligned_otus.qza"

	"""
	qiime alignment mask --i-alignment ${aligned_otus} --o-masked-alignment ${masked}

	"""
}


/*
Process 4(iv): Generating a Phylogenetic Tree
*/

process Phylogenetic_Tree {
	tag "Generating a Phylogenetic Tree"

	publishDir = "$params.output_dir"

	input:
	file(masked_output)

	output:
	file(unrooted_tree)

	script:

	unrooted_tree = 'unrooted_tree.qza'

	"""
	qiime phylogeny fasttree --i-alignment ${masked_output} --o-tree ${unrooted_tree}

	"""
}

/* Process 4(v):Mid-point rooting of the phylogenetic tree
*/
process Midpoint_root {
	tag "Mid-point rooting of the phylogenetic tree"

	publishDir "$params.output_dir"

	input:
	file(unrooted_tree)

	output:
	file(rooted)

	script:

	rooted = "rooted_tree.qza"

	"""
	qiime phylogeny midpoint-root --i-tree ${unrooted_tree} --o-rooted-tree ${rooted}
	
	"""
}

/*
Process 4(vi): Converting the OTU Table to Qiime Artifact
*/

process OTUtable_to_QiimeArtifact{

	tag "Converting OTU Table:"

	publishDir "$params.output_dir"

	input:
	file(otu_table)

	output:
	file(otubiomtable)

	script:

	otubiomtable = "otu_table.from_txt_hdf5.biom"

	"""
	biom convert -i ${otu_table} -o ${otubiomtable} --table-type="OTU table" --to-hdf5
        
        """
}


/*
Process 4(vi.2): Generating Feature Table
*/

process Feature_Table{
    tag "Generating Feature Table"

    publishDir "$params.output_dir"

    input:
    file(feature_tab)

    output:
    file(otutab_out)

    script:

    otutab_out = "otu_tab.qza"
    
    """
    qiime tools import --input-path ${feature_tab} --type 'FeatureTable[Frequency]' --output-path ${otutab_out}
    """
}


/*
Process 4(vii): Alpha and Beta Diversity Analysis
*/

process Diversity_Analysis {

    tag "Running Diversity Analysis:"

    publishDir "$params.output_dir"

    input:
    file(OTUtabs)


    script:

    meta.data = "practice.dataset1.metadata.tsv"

    """
    qiime diversity core-metrics --i-table ${OTUtabs} --p-sampling-depth 4000 --m-metadata-file ${meta.data} --output-dir core-metrics-results
        
    """ 
} 


