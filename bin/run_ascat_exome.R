#!/usr/bin/env Rscript
source("/opt/repo/renv/activate.R")
ibrary(ASCAT)
ibrary(dplyr)
ibrary(optparse)


########## Test for alleleCounter ##########

allelecounter_exe = "alleleCounter"

allelecount_status <- system("alleleCounter", intern = F, ignore.stdout = T)

print(allelecount_status)
########## Create an options list and parse options ##########

option_list<- list(
  make_option(c("--tum_bam"), action = "store_true", default = NA, type = "character", help = "Path to the tumour BAM file"), 
  make_option(c("--norm_bam"), action = "store_true", default = NA, type = "character", help = "Path to the normal BAM file"), 
  make_option(c("--tum_name"), action = "store_true", default = NA, type = "character", help = "Tumour sample name"), 
  make_option(c("--norm_name"), action = "store_true", default = NA, type = "character", help = "Normal sample name"), 
  make_option(c("--ref_file"), action = "store_true", default = NA, type = "character", help = "Reference genome file"), 
  make_option(c("--bed_file"), action = "store_true", default = NA, type = "character", help = "Bait regions used for WES"), 
  make_option(c("--sex"), action = "store_true", default = NA, type = "character", help = "Patient sex, XX or XY"), 
  make_option(c("--project_dir"), action = "store_true", type = "character", default = NA,  help = "This is the path of the project directory"), 
  make_option(c("--outdir" ), action = "store_true", type = "character", default = NA, help = "Path to the output directory")

)

arguments <- parse_args(OptionParser(option_list = option_list), positional_arguments = 0)

args <- arguments$options



########## Check arguments ##########

# Check BAMs

if (is.na(args$tum_bam)) {
	stop("Path to a tumour BAM must be provided with --tum_bam")
} else {
	if (! file.exists(args$tum_bam)) {
		stop(paste("Tumour BAM", args$tum_bam, "does not exist"))
	}
}

if (is.na(args$norm_bam)) {
	stop("Path to a normal BAM must be provided with --norm_bam")
} else {
	if (! file.exists(args$norm_bam)) {
		stop(paste("Normal BAM", args$norm_bam, "does not exist"))
	}
}


# Check sample names

if (is.na(args$tum_name) || is.na(args$norm_name)) {
	stop("Provide the tumour sample ID and normal sample ID with --tum_name and --norm_name")
}


# Check patient sex 

if (is.na(args$sex) || ((! is.na(args$sex) && (args$sex != "XX" && args$sex != "XY")))) {
	stop("Patient sex must be provided as --sex XX or --sex XY")
}


# Check project directory exists

if (is.na(args$project_dir)) {
	stop("Provide a path to the project directory with --project_dir")
} else {
	if (! dir.exists(args$project_dir)) {
		stop(paste("Directory does not exist:", args$project_dir))
	}
}

# Check output directory

if (is.na(args$outdir)) {
	stop("Provide a path to the output directory with --outdir")
} else {
	if (!dir.exists(args$outdir)) {
		dir.create(args$outdir)
		print(paste("Creating output directory", args$outdir))
	} else {
		print(paste("Output directory exist:", args$outdir))
	}
	print(paste("Moving to output directory", args$outdir))
	setwd(args$outdir)
	print(paste("Working dirctory is:", getwd()))
}


tum_bam <- args$tum_bam
norm_bam <- args$norm_bam
tum_name <- args$tum_name
norm_name <- args$norm_name
sex <- args$sex  # XX or XY
PROJECTDIR <- args$project_dir
outdir <- args$outdir

print(paste("Tumour BAM is", tum_bam))
print(paste("Normal BAM is", norm_bam))
print(paste("Tumour ID is", tum_name))
print(paste("Normal ID is", norm_name))
print(paste("Sex is", sex))
print(paste("Output dir is", outdir))



########## Check required input files ##########

# Shared reference files

ref_file <- args$ref_file
bed_file <- args$bait_file

# ASCAT/Battenberg files in project directory

alleles = paste0(PROJECTDIR, "/resources/ascat/1000G_loci_hg38_chr/1kg.phase3.v5a_GRCh38nounref_allele_index_chr")
loci = paste0(PROJECTDIR, "/resources/ascat/1000G_loci_hg38_chr/1kg.phase3.v5a_GRCh38nounref_loci_chr")
gc_file = paste0(PROJECTDIR, "/resources/ascat/1000G_GC_exome_chr.txt")
rt_file = paste0(PROJECTDIR, "/resources/ascat/1000G_RT_exome_chr.txt")

# Check that required inputs exist

for (file in c(ref_file, bed_file, gc_file, rt_file)) {
	if(! file.exists(file)) {
		stop(paste("Reference file does not exist:", file))
	} else {
		print(paste("Found:", file))
	}
}

for (prefix in c(alleles, loci)) {
	dirs <- dirname(prefix)
	if (! dir.exists(dirs)) {
		stop(paste("Directory does not exist:", dirs))
	} else {
		print(paste("Found:", dirs))
	}
}



########## Run ASCAT ##########

# Run prepareHTS with a fixed seed for reproducibility

ascat.prepareHTS(
       tumourseqfile = tum_bam,
       normalseqfile = norm_bam,
       tumourname = tum_name,
       normalname = norm_name,
       allelecounter_exe = allelecounter_exe,
       alleles.prefix = alleles,
       loci.prefix = loci,
       gender = sex,
       genomeVersion = "hg38",
       nthreads = 8,
       tumourLogR_file = NA,
       tumourBAF_file = NA,
       normalLogR_file = NA,
       normalBAF_file = NA,
       minCounts = 10,
       BED_file = bed_file,
       probloci_file = NA,
       chrom_names = c(1:22, "X"),
       min_base_qual = 20,
       min_map_qual = 35,
       ref.fasta = ref_file,
       skip_allele_counting_tumour = F,
       skip_allele_counting_normal = F,
       seed = 485028101
       #seed = as.integer(Sys.time())
)



########## Load the data produced by prepareHTS and plot raw data ##########

ascat.bc = ascat.loadData(
	Tumor_LogR_file = paste0(tum_name, "_tumourLogR.txt"), 
	Tumor_BAF_file = paste0(tum_name, "_tumourBAF.txt"),
	Germline_LogR_file = paste0(tum_name, "_normalLogR.txt"),
	Germline_BAF_file = paste0(tum_name, "_normalBAF.txt"),
	gender = sex , genomeVersion = "hg38"
)

ascat.plotRawData(ascat.bc, img.prefix = "Before_correction_")


########## Run GC and RT correction and make plots ##########

ascat.bc = ascat.correctLogR(ascat.bc, GCcontentfile = gc_file, replictimingfile = rt_file)
ascat.plotRawData(ascat.bc, img.prefix = "After_correction_")
ascat.bc = ascat.aspcf(ascat.bc, penalty = 70, seed = 483024451)
ascat.plotSegmentedData(ascat.bc)


########## Get ascat outputs and QC metrics ##########

ascat.output = ascat.runAscat(ascat.bc, gamma=1, write_segments = T)
QC = ascat.metrics(ascat.bc,ascat.output)

write.table(QC, file = paste0("QC_", tum_name, "_", norm_name, ".tsv"), sep = "\t", quote = F)


########## Output the estimates to a file ##########

lines <- c(
	paste("Sex", ascat.bc$gender, sep = "\t"),
	paste("Purity", ascat.output$purity, sep = "\t"),
	paste("Ploidy", ascat.output$ploidy, sep = "\t"),
	paste("Psi", ascat.output$psi, sep = "\t"),
	paste("Goodness-of-fit", ascat.output$goodnessOfFit, sep = "\t")
)

writeLines(lines, paste0("ASCAT_estimates_", tum_name, "_", norm_name, ".tsv"))


########## Make GISTIC2 input file ##########

all_segs <- data.frame()

for (i in 1:nrow(ascat.output$segments)) {
	seg <- ascat.output$segments[i, ] 
	seg_logR <- ascat.bc$Tumor_LogR_segmented[ rownames(ascat.bc$SNPpos %>% filter(Chromosome %in% seg$chr & Position >= seg$startpos & Position <= seg$endpos)), ]
	markers <- length(seg_logR)
	logR <- mean(seg_logR)
	seg <- seg %>% mutate(markers = markers) %>% mutate(logR = logR) %>%
			select(-c(nMajor, nMinor))
	all_segs <- rbind(all_segs, seg)
}

save(ascat.bc, ascat.output, QC, all_segs, file = 'ASCAT_objects.Rdata')

colnames(all_segs) <- c("Sample", "Chromosome", "Start Position", "End Position", "Num Markers", "Seg.CN")
write.table(all_segs, file = paste0("gistic2_segs_", tum_name, "_", norm_name , ".tsv"), col.names = F, row.names = F, quote = F, sep = "\t")


