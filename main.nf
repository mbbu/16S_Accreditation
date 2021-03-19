nextflow.enable.dsl = 2

include {OTU_conversion; MAFFT_alignment; Masking; Phylogenetic_Tree; Midpoint_root; OTUtable_to_QiimeArtifact; Feature_Table}from './nextflow.nf' 

workflow {
	// step 1
	input_ch = channel.fromPath(params.otufastq)
	OTU_conversion(input_ch)

	// step 2
	MAFFT_alignment(OTU_conversion.out)			
	
	// step 3
	Masking(MAFFT_alignment.out)	
	
	// step 4
	Phylogenetic_Tree(Masking.out)

	// step 5
	Midpoint_root(Phylogenetic_Tree.out)

	// step 6
	inp_ch = channel.fromPath(params.otu_txt)
	OTUtable_to_QiimeArtifact(inp_ch)
	
        //step 7
         Feature_Table(OTUtable_to_QiimeArtifact.out)			
}
