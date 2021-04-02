#! usr/bin/env Rscript
library(profvis)
#document the resources used ant time it takes
profvis({
library(dada2)
packageVersion("dada2") 

#setwd("path to working directory")

list.files() #make sure what we think is here is actually here

## first we're setting a few variables we're going to use ##
# one with all sample names, by scanning our "samples" file we made earlier
#samples <- scan("samples", what="character")- this code worked in conjunction with a bash script
#reading sample names using r
ForwardF <- sort(list.files(, pattern= c("*_R1.fastq"), full.names = TRUE))
ForwardR <- sort(list.files(, pattern= c("*_R2.fastq"), full.names = TRUE))
reads <- c(ForwardF,ForwardR)
samples <- sapply(strsplit(basename(reads), "_"), `[`, 1)

# one holding the file names of all the forward reads
forward_reads <- paste0(samples, "_R1.fastq")
# and one with the reverse
reverse_reads <- paste0(samples, "_R2.fastq")

# and variables holding file names for the forward and reverse
# filtered reads we're going to generate below
filtered_forward_reads <- paste0(samples, "_R1_filtered.fastq.gz")
filtered_reverse_reads <- paste0(samples, "_R2_filtered.fastq.gz")

#plot quality profile. this will inform the trimming
rawplotFreads <- plotQualityProfile(forward_reads)
rawplotRreads <- plotQualityProfile(reverse_reads)
#Saving plot into a specified format
dev.copy(pdf,'rawplot.pdf')
dev.off()
#looking at specific samples quality profile
rawplotR <- plotQualityProfile(reverse_reads[5])
rawplotF <- plotQualityProfile(forward_reads[5])

#trimming and filtering

filtered_out <- filterAndTrim(forward_reads, filtered_forward_reads,
                              reverse_reads, filtered_reverse_reads, maxEE=c(3,3),
                              rm.phix=TRUE, truncLen=c(230,200), trimLeft = c(25,25), multithread = TRUE)

#checking the quality profile again

forward_errorplt <- plotQualityProfile(filtered_reverse_reads[5])
reverse_errorplt <- plotQualityProfile(filtered_forward_reads[5])

#how many reads did we lose
dim(filtered_out)
filtered_out

#generating an error model from our data
#by learn error rates
err_forward_reads <- learnErrors(filtered_forward_reads, multithread = TRUE)
saveRDS(err_forward_reads,"error_forward.rds")
err_reverse_reads <- learnErrors(filtered_reverse_reads, multithread = TRUE)
saveRDS(err_reverse_reads,"error_reverse.rds")# this step takes a lot of computational power, this is why we save the output in a file to avoid repeating the step


#checking the error

forward_error_plot <- plotErrors(err_forward_reads, nominalQ=TRUE)
reverse_error_plot <- plotErrors(err_reverse_reads, nominalQ=TRUE)


#Dereplicating reads

derep_forward <- derepFastq(filtered_forward_reads, verbose=TRUE)
names(derep_forward) <- samples # the sample names in these objects are initially the file names of the samples, this sets them to the sample names for the rest of the workflow
derep_reverse <- derepFastq(filtered_reverse_reads, verbose=TRUE)
names(derep_reverse) <- samples

#inferring asvs
dada_forward <- dada(derep_forward, err=err_forward_reads, pool="pseudo")
dada_reverse <- dada(derep_reverse, err=err_reverse_reads, pool="pseudo")

#MERGING READS

#MERGING THE DADA CLASS OBJECTS FORWARD And reverse then inspecting them
merged_amplicons <- mergePairs(dada_forward, derep_forward, dada_reverse,
                               derep_reverse, trimOverhang=TRUE)


#constructing a sequence table

seqtab <- makeSequenceTable(merged_amplicons)
class(seqtab)
dim(seqtab)
#To view lengths of the merged sequences
table(nchar(getSequences(seqtab)))
  
#noticed the lengths of 3 merged sequences out of range.
#to remove sequences out of range  
#`%notin%` <- Negate(`%in%`)
#seqtab2 <- seqtab[,nchar(colnames(seqtab)) %notin% 251:253]
#noticed the lengths of 3 merged sequences out of range but if remove affects the next step adversly hence retained them.

#REMOVING BIMERAS

seqtab.nochim <- removeBimeraDenovo(seqtab, verbose=T) 


sum(seqtab.nochim)/sum(seqtab)#gives the percentage of reads retained. 

#tracking reads throughout the pipeline

# set a little function
getN <- function(x) sum(getUniques(x))

# making a sequence table
summary_tab <- data.frame(row.names=samples, dada2_input=filtered_out[,1],
                          filtered=filtered_out[,2], dada_f=sapply(dada_forward, getN),
                          dada_r=sapply(dada_reverse, getN), merged=sapply(merged_amplicons, getN),
                          nonchim=rowSums(seqtab.nochim),
                          final_perc_reads_retained=round(rowSums(seqtab.nochim)/filtered_out[,1]*100, 1))

summary_tab
#SAVE the sequence yable
write.table(summary_tab, "read-count-tracking.tsv", quote=FALSE, sep="\t", col.names=NA)

#ASSIGNING TAXONOMY


taxa <- assignTaxonomy(seqtab.nochim,"/data/asatsa/dada2_preprocess/dada2_amplicon_ex_workflow/refdb/silva_nr99_v138.1_train_set.fa",tryRC = TRUE)



# count table:
#asv_tab <- t(seqtab.nochim)
#row.names(asv_tab) <- sub(">", "", asv_headers)
#write.table(asv_tab, "ASVs_counts.tsv", sep="\t", quote=F, col.names=NA)

#write.table(asv_tax, "ASVs_taxonomy.tsv", sep = "\t", quote=F, col.names=NA)


#phylogenetic tree
sequences<-getSequences(seqtab.nochim)
names(sequences)<-sequences
library("DECIPHER")
library("phyloseq")
library("phangorn")
#aligning sequences using MSA
alignment <- AlignSeqs(DNAStringSet(sequences), anchor=NA)
phang.align <- phyDat(as(alignment, "matrix"), type="DNA")
#assigning distance matrix
dm <- dist.ml(phang.align)
#creating the phylogenetic tree
treeNJ <- NJ(dm)
fit = pml(treeNJ, data=phang.align)
fitGTR <- update(fit, k=4, inv=0.2)
fitGTR <- optim.pml(fitGTR, model="GTR", optInv=TRUE, optGamma=TRUE,
                    rearrangement = "stochastic", control = pml.control(trace = 0))




#creating a phyloseq object
#Loading necessary libraries

library(vegan)
library(ggplot2)
library(dplyr)
library(scales)
library(grid)
library(reshape2)
library(phyloseq)

library('phyloseq')
samdata <- read.table("set5_meta.txt",header = TRUE,row.names = "sample")
phyloseq_object <- phyloseq(otu_table(seqtab.nochim,taxa_are_rows=FALSE),sample_data(samdata),tax_table(taxa),phy_tree(fitGTR$tree))
#renaming with ASV instead of a Dna string
sequences <- Biostrings::DNAStringSet(taxa_names(phyloseq_object))
names(sequences) <- taxa_names(phyloseq_object)
phyloseq_object <- merge_phyloseq(phyloseq_object, sequences)
phyloseq_object
#paste a unique identifier
taxa_names(phyloseq_object) <- paste0("ASV", seq(ntaxa(phyloseq_object)))

#save phyloseq object
saveRDS(phyloseq_object,"phyloseq_object.rds")

#visualising alpha diversity
#this should be specific to your data
#visualising alpha diversity

diversitybyinflammation <-plot_richness(phyloseq_object, x="BMI", measures=c("Shannon", "Simpson"), color="Inflammation") + theme_bw()
saveRDS(diversitybyinflammation,"divbyinf.png")
#plotbars

top10 <- names(sort(taxa_sums(phyloseq_object), decreasing=TRUE))[1:10]
ps.top10 <- transform_sample_counts(phyloseq_object, function(OTU) OTU/sum(OTU))
ps.top10 <- prune_taxa(top10, ps.top10)
top10plot <- plot_bar(ps.top10, x="BMI", fill="Age") + facet_wrap(~Inflammation, scales="free_x")
#THE ABOVE CODE IS PRODUCING NOT GOOD GRAPHS 

#p values,shanon observed and simpson parameters

R <- estimate_richness(phyloseq_object,split = TRUE,measures = c("Observed","Shannon"))

R1 <- estimate_richness(phyloseq_object,split = TRUE,measures = c("Observed","simpson"))
#beta diversity
#PCoA plot
ps_pcoa <- ordinate(
  physeq = phyloseq_object,
  method = "PCoA",
  distance = "bray")
##Pcoa plot code not working yet
#RAREFACTION CURVE
#CREATING A COLOUR PALLETE
library(RColorBrewer)
d <- min(otu_table(phyloseq_object))
col <- comb
Ity <- "solid"
Iwd <- 2
pars <- expaisplay.brewer.all()#display all palletes
pal1 <- brewer.pal(11,"Paired")
pal2 <- brewer.pal(8,"Dark2")
pal3 <- brewer.pal(4,"Set1")
comb <- c(pal2,pal3)

pars <- expand.grid(col=col,Ity=Ity,stringsAsFactors = TRUE)
with(pars[1:20,],rarecurve(otu_table(phyloseq_object),step = 150,ylab = "ObservedRSVs",xlab="number of reads",main="Rarefaction curves",xlim=c(0,$=comb)
  

                           
                         
})
