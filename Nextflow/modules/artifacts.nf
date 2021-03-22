#! /usr/bin/env nextflow

// Process 4(i): Conversion of OTUS into Qiime2 Artifact
process OTU_CONVERSION {
	tag "OTU conversion"

	publishDir path: { "${params.outdir}/artifacts" }

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

// Process 4(ii): MAFFT alignment
process MAFFT_ALIGNMENT {
	tag "Running MAFFT_alignment"
	publishDir path: { "${params.outdir}/artifacts" }

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

// Process 4(iii): Masking Aligned OTUS
process MASKING {
	tag " masking_aligned_otus"
  	publishDir path: { "${params.outdir}/artifacts" }

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

// Process 4(iv): Generating a Phylogenetic Tree
process PHYLOGENY {
	tag "Generating a Phylogenetic Tree"
  	publishDir path: { "${params.outdir}/artifacts" }

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

// Process 4(v):Mid-point rooting of the phylogenetic tree
process MIDPOINT_ROOTING {
	tag "Mid-point rooting of the phylogenetic tree"
  	publishDir path: { "${params.outdir}/artifacts" }

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

// Process 4(vi): Converting the OTU Table to Qiime Artifact
process OTUTABLE_TO_ARTIFACT {
	tag "Converting OTU Table:"
  	publishDir path: { "${params.outdir}/artifacts" }

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

// Process 4(vi.2): Generating Feature Table
process FEATURE_TABLE {
	tag "Generating Feature Table"
	publishDir path: { "${params.outdir}/artifacts" }

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
