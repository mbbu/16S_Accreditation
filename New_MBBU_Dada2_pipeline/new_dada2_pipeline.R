#! usr/bin/env Rscript
library(profvis)
#document the resources used and time it takes
profvis({
library(dada2)
packageVersion("dada2") 

#setwd("path to working directory")
data <- readline(prompt = "Enter the file path for the data: ") #provide a path for the input data 

list.files(data) #make sure what we think is here is actually here

##first we're setting a few variables we're going to use 
#one with all sample names, by scanning the "samples" file we made earlier
#samples <- scan("samples", what="character")- this code worked in conjunction with a bash script
#reading sample names using r
Forward <- sort(list.files(data, pattern= c("*_L001_R1_001.fastq.gz"), full.names = TRUE))
Forward
Reverse <- sort(list.files(data, pattern= c("*_L001_R2_001.fastq.gz"), full.names = TRUE))
Reverse
reads <- c(Forward,Reverse)
reads
samples_F <- sapply(strsplit(basename(Forward), "_"), `[`, 1)
samples_F
samples_R <- sapply(strsplit(basename(Reverse), "_"), `[`, 1)
samples_R
#one holding the file names of all the forward reads
forward_reads <- paste0(samples_F, "_L001_R1_001.fastq.gz")
forward_reads
#one with the reverse reads
reverse_reads <- paste0(samples_R, "_L001_R2_001.fastq.gz")
reverse_reads
#and variables holding file names for the forward and reverse
#filtered reads we're going to generate below
filtered_Forward <- paste0(samples_F, "_L001_R1_001.filtered.fastq.gz")
filtered_Forward
filtered_Reverse <- paste0(samples_R, "_L001_R2_001.filtered.fastq.gz")
filtered_Reverse
#plot quality profile. This will inform the trimming
rawplotFreads <- plotQualityProfile(Forward)
rawplotFreads
rawplotRreads <- plotQualityProfile(Reverse)
rawplotRreads
#saving plot into a specified format
dev.copy(pdf,'rawplot.pdf')
dev.off()
#looking at specific samples quality profile
rawplotF <- plotQualityProfile(Forward[2])
rawplotF
rawplotR <- plotQualityProfile(Reverse[2])
rawplotR
#plotting quality profiles for random samples (in this case, 20 Samples)
random_samples <- sample(size = 2, 1:length(Reverse)) 
random_samples
fwd_qual_plots <- plotQualityProfile(Forward[random_samples])
fwd_qual_plots
rev_qual_plots <- plotQualityProfile(Reverse[random_samples])
rev_qual_plots


#trimming and filtering

filtered_out <- filterAndTrim(Forward, filtered_Forward,
                              Reverse, filtered_Reverse, maxEE=c(3,3),
                              rm.phix=TRUE, truncLen=c(230,200), trimLeft = c(25,25), multithread = TRUE)
filtered_out
#checking the quality profile after trimming and filtering

forward_errorplt <- plotQualityProfile(filtered_Forward[2])
forward_errorplt
reverse_errorplt <- plotQualityProfile(filtered_Reverse[2])
reverse_errorplt
  
# plotting quality profiles for random samples after trimming and filtering
filtrandom_samples <- sample(size = 2, 1:length(filtered_Forward))
filtrandom_samples
filtfwd_qual_plots <- plotQualityProfile(filtered_Forward[filtrandom_samples])
filtfwd_qual_plots
filtrev_qual_plots <- plotQualityProfile(filtered_Reverse[filtrandom_samples])
filtrev_qual_plots

#the reads that were lost
dim(filtered_out)
filtered_out

#generating an error model from our data
#by learn error rates
#this step takes a lot of computational power, this is why we save the output in a file to avoid repeating the step
err_forward_reads <- learnErrors(filtered_Forward, multithread = TRUE)
err_forward_reads
saveRDS(err_forward_reads,"error_forward.rds")
err_reverse_reads <- learnErrors(filtered_Reverse, multithread = TRUE)
err_reverse_reads
saveRDS(err_reverse_reads,"error_reverse.rds")


#checking the error

forward_error_plot <- plotErrors(err_forward_reads, nominalQ=TRUE)
forward_error_plot
reverse_error_plot <- plotErrors(err_reverse_reads, nominalQ=TRUE)
reverse_error_plot


#Dereplicating reads

derep_forward <- derepFastq(filtered_Forward, verbose=TRUE)
derep_forward
names(derep_forward) <- samples_F #the sample names in these objects are initially the file names of the samples, this sets them to the sample names for the rest of the workflow
names(derep_forward)
derep_reverse <- derepFastq(filtered_Reverse, verbose=TRUE)
names(derep_reverse) <- samples_R
names(derep_reverse)

#inferring asvs
dada_forward <- dada(derep_forward, err=err_forward_reads, pool="pseudo", multithread = TRUE)
dada_forward
dada_reverse <- dada(derep_reverse, err=err_reverse_reads, pool="pseudo", multithread = TRUE)
dada_reverse

#merging reads

#merging the DADA class forward and reverse objects then inspecting them
merged_amplicons <- mergePairs(dada_forward, derep_forward, dada_reverse,
                               derep_reverse, trimOverhang=TRUE)
merged_amplicons


#constructing a sequence table

seqtab <- makeSequenceTable(merged_amplicons)
seqtab
class(seqtab)
dim(seqtab)
#to view lengths of the merged sequences
table(nchar(getSequences(seqtab)))
  
#noticed the lengths of 3 merged sequences out of range.
#to remove sequences out of range  
#`%notin%` <- Negate(`%in%`)
#seqtab2 <- seqtab[,nchar(colnames(seqtab)) %notin% 251:253]
#noticed the lengths of 3 merged sequences out of range but if remove affects the next step adversly hence retained them.

#removing bimeras

seqtab.nochim <- removeBimeraDenovo(seqtab, verbose=T) 


sum(seqtab.nochim)/sum(seqtab)#gives the percentage of reads retained. 
sum
#tracking reads throughout the pipeline

#set a little function
getN <- function(x) sum(getUniques(x))
getN
#making a sequence table
summary_tab <- data.frame(row.names=samples_R, dada2_input=filtered_out[,1],
                          filtered=filtered_out[,2], dada_f=sapply(dada_forward, getN),
                          dada_r=sapply(dada_reverse, getN), merged=sapply(merged_amplicons, getN),
                          nonchim=rowSums(seqtab.nochim),
                          final_perc_reads_retained=round(rowSums(seqtab.nochim)/filtered_out[,1]*100, 1))

summary_tab
#saving the sequence table
write.table(summary_tab, "read-count-tracking.tsv", quote=FALSE, sep="\t", col.names=NA)

#assigning taxonomy


#taxa <- assignTaxonomy(seqtab.nochim,"/data/asatsa/dada2_preprocess/dada2_amplicon_ex_workflow/refdb/silva_nr99_v138.1_train_set.fa",tryRC = TRUE)

#taxa <- addSpecies(taxa, "/data/asatsa/dada2_preprocess/dada2_amplicon_ex_workflow/refdb/silva_species_assignment_v138.1.fa.gz",tryRC = TRUE)

taxa <- readline(prompt = "Enter the file path for the silva reference database: ")
  
write.table(taxa, "taxa_silva_taxonomy.tsv", sep = "\t", quote=F, col.names=NA) 

#alternative training database in assigning taxonomy. 
#taxa_rdp <- assignTaxonomy(seqtab.nochim,"/data/kauthar/Dada2/training_data/rdp_train_set_18.fa",tryRC = TRUE)

#write.table(taxa_rdp, "taxa_rdp_taxonomy.tsv", sep = "\t", quote=F, col.names=NA)
  
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
phang.align
#assigning distance matrix
dm <- dist.ml(phang.align)
#creating the phylogenetic tree
treeNJ <- NJ(dm)
treeNJ
fit = pml(treeNJ, data=phang.align)
fit
fitGTR <- update(fit, k=4, inv=0.2)
fitGTR
fitGTR <- optim.pml(fitGTR, model="GTR", optInv=TRUE, optGamma=TRUE,
                    rearrangement = "stochastic", control = pml.control(trace = 0), multithread = TRUE)
fitGTR
saveRDS(fitGTR,"phylogenetic_tree.rds")
#rooting the tree
#set.seed(711)
#phy_tree(phyloseq_object) <- root(phy_tree(phyloseq_object), sample(taxa_names(phyloseq_object), 1), resolve.root = TRUE)
#phy_tree(phyloseq_object)
#is.rooted(phy_tree(phyloseq_object))


#Taxonomy plots.
#Phylum
#phylum_plot <-  plot_bar(phyloseq_object, x="sample", fill="Phylum") + facet_wrap(~BV, scales="free_x")
#phylum_plot
#Genus
#top50 <- names(sort(taxa_sums(phyloseq_object), decreasing=TRUE))[1:50]
#ps.top50 <- transform_sample_counts(phyloseq_object, function(OTU) OTU/sum(OTU))
#ps.top50 <- prune_taxa(top50, ps.top50)
#Genus_plot <-  plot_bar(ps.top50, x="sample", fill="Genus") + facet_wrap(~BV, scales="free_x")
#Genus_plot
  
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
#NB: Provide a path to the set5_meta.txt file and ensure your file has the sample column labelled sample if not add the label. 
samdata <- read.table("path/to/the/metadt.tsv", header = TRUE, sep="\t", row.names = samples_F)
samples_F
samdata
phyloseq_object <- phyloseq(otu_table(seqtab.nochim,taxa_are_rows=FALSE),sample_data(samdata),tax_table(taxa),phy_tree(fitGTR$tree))

#rooting a the tree
set.seed(711)
phy_tree(phyloseq_object) <- root(phy_tree(phyloseq_object), sample(taxa_names(phyloseq_object), 1), resolve.root = TRUE)
phy_tree(phyloseq_object)
is.rooted(phy_tree(phyloseq_object))

#renaming with ASV instead of a Dna string
sequences <- Biostrings::DNAStringSet(taxa_names(phyloseq_object))
sequences
taxa_names(phyloseq_object)
names(sequences) <- taxa_names(phyloseq_object)
names(sequences)
phyloseq_object <- merge_phyloseq(phyloseq_object, sequences)
phyloseq_object
#paste a unique identifier
taxa_names(phyloseq_object) <- paste0("ASV", seq(ntaxa(phyloseq_object)))
taxa_names(phyloseq_object)
#save phyloseq object
saveRDS(phyloseq_object,"phyloseq_object.rds")

#visualising alpha diversity
#this should be specific to your data

diversitybyinflammation <-plot_richness(phyloseq_object, x="SampleID", measures=c("Shannon", "Simpson"), color="target_gene") + theme_bw()
diversitybyinflammation
saveRDS(diversitybyinflammation,"divbyinf.png")
#plot bars

top30 <- names(sort(taxa_sums(phyloseq_object), decreasing=TRUE))[1:30]
top30
ps.top30 <- transform_sample_counts(phyloseq_object, function(OTU) OTU/sum(OTU))
ps.top30
ps.top30 <- prune_taxa(top30, ps.top30)
ps.top30
top30plot <- plot_bar(ps.top30, x="SampleID", fill="treatment1") + facet_wrap(~SampleID, scales="free_x")
top30plot


#To a use BMI in facet wrapping, we needed to mutate the sample data into 4 groups. This step required creation of a new phyloseq object
# however this is not essential
#library(tidyverse)
#metadata <-  read.table("/node/cohort4/nelly/16s-rRNA-Project/practice.dataset1.meta.txt", sep = "\t", header = T,row.names = sample) # remember to add path to your metadatafile
#metadata
#yy <-  metadata %>%
 #  mutate(status = BMI) %>% 
 #  mutate(status = ifelse(status >= 30 , "Obese", status)) %>%
 #  mutate(status = ifelse(status <= 18.5, "Underweight", status)) %>% 
 #  mutate(status = ifelse(status > 18.5 & status < 25, "Normal", status)) %>% 
 #  mutate(status = ifelse(status >= 25 & status < 30, "Overweight", status)) 

#Second phyloseq object to be used in plotting, that incoparates the mutated metadata file.
#phyloseq_object_yy <- phyloseq(otu_table(seqtab.nochim,taxa_are_rows=FALSE),sample_data(yy),tax_table(taxa),phy_tree(fitGTR$tree))

#bar plot of BV using inflammation as fill and facet wrapping with status i.e categories of BMI
#barplot2<- plot_bar(phyloseq_object_yy, x="BV", fill="Inflammation") + facet_wrap(~status, scales="free_x") 
  
#bar plot of BV using BMI as fill and facet wrapping with Inflamation.
#barplot1<- plot_bar(phyloseq_object, x="BV", fill="BMI") + facet_wrap(~Inflammation, scales="free_x") 

#p values,shanon observed and simpson parameters

#R <- estimate_richness(phyloseq_object,split = TRUE,measures = c("Observed","Shannon"))

#R1 <- estimate_richness(phyloseq_object,split = TRUE,measures = c("Observed","simpson"))
#alpha diversity plots
#p <- plot_richness_estimates(phyloseq_object, "BV", "Inflammation")
#(p <- p + geom_boxplot(data = p$data, aes(x = BV, y = value, color = NULL),
 #                      alpha = 0.5))

#beta diversity
#PCoA plot
ps_pcoa <- ordinate(
  physeq = phyloseq_object,
  method = "PCoA",
  distance = "bray")

PCoa <- plot_ordination(physeq = phyloseq_object, ordination = ps_pcoa, color = "SampleID", shape = "bad3", title = "PCOA" +geom_point(aes(color = Treatment ), alpha = 0.5, size = 4) +geom_point(colour = "grey90", size = 1.5))
PCoa
saveRDS(PCoa,"PCoa.rds") 

#rarefaction curve
#creating a color pallete
library(RColorBrewer)
d <- min(otu_table(phyloseq_object))
d
Ity <- "solid"
Iwd <- 2
pars <- display.brewer.all() #display all palletes
pars
pal1 <- brewer.pal(11,"Paired")
pal1
pal2 <- brewer.pal(8,"Dark2")
pal2
pal3 <- brewer.pal(4,"Set1")
comb
comb <- c(pal2,pal3)
col <- comb
col

#pars <- expand.grid(col=col,Ity=Ity,stringsAsFactors = TRUE)
#with(pars[1:20,],rarecurve(otu_table(phyloseq_object),step = 150,ylab = "ObservedRSVs",xlab="number of reads",main="Rarefaction curves",xlim=c(0,$=comb)
#the above rarefaction method is not working

#creating a rarefaction curve
rare <- rarecurve(seqtab.nochim, step=150, lwd=2, ylab="ASVs", label=F)
# and adding a vertical line at the fewest seqs in any sample
abline(v=(min(rowSums(seqtab.nochim))))   
#this data has not been transformed, I don't like the way the plot looks

#Taxonomy plots.
#Phylum
phylum_plot <-  plot_bar(phyloseq_object, x="SampleID", fill="Phylum") + facet_wrap(~treatment1, scales="free_x")
phylum_plot
#Genus
top50 <- names(sort(taxa_sums(phyloseq_object), decreasing=TRUE))[1:50]
top50
ps.top50 <- transform_sample_counts(phyloseq_object, function(OTU) OTU/sum(OTU))
ps.top50
ps.top50 <- prune_taxa(top50, ps.top50)
ps.top50
Genus_plot <-  plot_bar(ps.top50, x="SampleID", fill="Genus") + facet_wrap(~materialSampleID, scales="free_x")
Genus_plot                          
                         
})


