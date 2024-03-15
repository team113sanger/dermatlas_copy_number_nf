suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(IRanges))
suppressPackageStartupMessages(library(GenomicRanges))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(stringr))

# ASCAT format:
#
# sample  chr     startpos        endpos  nMajor  nMinor
# PD56509a        1       69511   84814219        1       1
# PD56509a        1       84865322        86642692        2       1
# PD56509a        1       86704810        103714098       1       1
# PD56509a        1       107056751       114399628       2       1
# PD56509a        1       114401312       121568263       1       1

# Plotting format:
#
#Group	Subgroup	Value	CN	Count
#1	1	0	Neutral	NA
#1	2	0	Neutral	NA
#1	3	0	Neutral	NA
#1	4	0.105392156862745	Gain	43
#1	4	-0.0833333333333333	Loss	34
#1	5	0.112745098039216	Gain	46
#1	5	-0.0931372549019608	Loss	38
#1	6	0.112745098039216	Gain	46


# chrSize = a named numeric vector

# chrsizes hg38
chrnames <- c(1:22, "X")
chrSizes <- c(
	248956422,
	242193529,
	198295559,
	190214555,
	181538259,
	170805979,
	159345973,
	145138636,
	138394717,
	133797422,
	135086622,
	133275309,
	114364328,
	107043718,
	101991189,
	90338345,
	83257441,
	80373285,
	58617616,
	64444167,
	46709983,
	50818468,
	156040895
)


##### Command line arguments #####

args <- commandArgs(trailingOnly = TRUE)

# List segement files from ASCAT
filelist <- args[1]

# Ploidy and purity: Sample[tab]Purity[tab]Ploidy
ploidy_list <- args[2]

# Patient sex: Sample[tab]Sex
sample2sex_list <- args[3]

# Output file name prefix
outfile <- args[4]

# Optional segment size cutoff (bp)
minsize <- as.numeric(args[5])


##### Check options #####

if (is.na(filelist)) {
	stop("Input a file of segmentation file names (segment data from ASCAT)")
} else if (is.na(ploidy_list)) {
	stop("Input a file with purity and ploidy estimates by sample")
} else if (is.na(sample2sex_list)) {
	stop("Input a file with sample and patient sex")
} else if (is.na(outfile)) {
	stop("Input a output file prefix")
}

if (is.na(minsize)) {
	minsize = 0
}

print(paste("Minimum segment size is", minsize))


################## Functions ######################

# Draw a frequency plot of cn-LOH regions

plot_cn_loh <- function(df, outfile, which) {
	#loh_plot <- ggplot(data = df, aes_string(x = "Subgroup", y = "Value", group = "Group", fill = "CN")) +
	loh_plot <- ggplot(data = df, aes(x = Subgroup, y = Value, group = Group, fill = CN)) +
			geom_bar(stat = "identity", width = 1) +
			scale_x_discrete(breaks = df$Group, labels = NULL, expand = c(0.0,0.0)) +
			scale_y_continuous(breaks = c(0,0.5,1), limits = c(0, 1), expand = c(0.003, 0.003), labels = c("0.0","0.5","1.0")) +
			facet_grid(~ Group, space = "free_x", scales = "free_x", switch = "x") +
			theme_bw() +
			ggtitle(paste("Frequency of cn-LOH - ", which, "; ", wsize, " windows (n = ", totsamples, ")", sep = "")) +
			theme(strip.placement = "outside",
					plot.title = element_text(size = 8),
					strip.background = element_blank(),
					panel.border = element_rect(colour = "grey25", size = 0.1, linetype = "solid"),
					panel.spacing = unit(0.0, "cm"),
					panel.grid.major.x = element_blank(),
					panel.grid.minor.y = element_blank(),
					panel.grid.major.y = element_line(size = 0.5),
					legend.position = "none",
					strip.text.x = element_text(size = 5),
					strip.text.y = element_text(size = 6),
					axis.text.y = element_text(size = 6),
					axis.title.y = element_text(size = 7),
					axis.line.y = element_line()
			) +
			labs(x = "", y = "Frequency") +
			scale_fill_manual(values = c("blue","orange"), na.translate = FALSE) +
			geom_hline(yintercept = 0, linetype = "solid",color = "black", size = 0.4)

	pdf(outfile, width = 7.5, height = 3)
	print(loh_plot)
	dev.off()

}

# Draw a penetrance plot

plot_freq <- function(df, outfile, which) {
	fq_plot <- ggplot(data = df, aes(x = Subgroup, y = Value, group = Group, fill = CN)) +
	#fq_plot <- ggplot(data = df, aes_string(x = "Subgroup", y = "Value", group = "Group", fill = "CN")) +
		geom_bar(stat = "identity", width = 1) + 
		scale_x_discrete(breaks = df$Group, labels = NULL, expand = c(0.0,0.0)) +
		scale_y_continuous(breaks = c(-1,-0.5,0,0.5,1), limits = c(-1, 1), expand = c(0.003, 0.003), labels = c("1.0","0.5","0.0","0.5","1.0")) +	
		facet_grid(~ Group, space = "free_x", scales = "free_x", switch = "x") + 
		theme_bw() +
		ggtitle(paste("Frequency of SCNAs - ", which, " gains or losses; ", wsize, " windows (n = ", totsamples, ")", sep = "")) +
		theme(strip.placement = "outside",
			plot.title = element_text(size = 8),
			strip.background = element_blank(),
			panel.border = element_rect(colour = "grey25", size = 0.1, linetype = 'solid'),
			panel.spacing = unit(0.0, "cm"),
			panel.grid.major.x = element_blank(),
			panel.grid.minor.y = element_blank(),
			panel.grid.major.y = element_line(size = 0.5),
			legend.title = element_blank(),
			legend.position = "bottom",
			legend.key.size = unit(0.25, "cm"),
			legend.text = element_text(size = 6),
			strip.text.x = element_text(size = 5),
			strip.text.y = element_text(size = 6),
			axis.text.y = element_text(size = 6),
			axis.title.y = element_text(size = 7),
			axis.line.y = element_line()
		) +
		labs(x = "", y = "Frequency") +
		scale_fill_manual(values = c("blue","orange"), na.translate = FALSE) +
		geom_hline(yintercept = 0, linetype = "solid",color = "black", size = 0.4)
		

	pdf(outfile, width = 7.5, height = 3)
	print(fq_plot)
	dev.off()
}

# Make counts matrix
# For each chromosome, create IRanges objects and find overlap with 1Mb regions

get_counts <- function(segments, cn_types) {

	cn_counts <- data.frame()
	for (chrom in c(1:22, "X")) {
		ref_genome <- bins[seqnames(bins) == chrom]
		for (cn in cn_types) {
			# filter segments by size, if requested
			if (cn %in% c('gain', 'loss')) {
				if (minsize > 0) {
					sample_chrom_segs <- segments %>% filter(chr == chrom & CN == cn & Size >= minsize)
				} else {
					sample_chrom_segs <- segments %>% filter(chr == chrom & CN == cn)
				}
			} else if (cn == 'cn-loh') {
				if (minsize > 0) {
					sample_chrom_segs <- segments %>% filter(! (Sex == 'M' & chr == 'X') & chr == chrom & CN == 'neutral' & Size >= minsize & nMinor == 0)
				} else {
					sample_chrom_segs <- segments %>% filter(! (Sex == 'M' & chr == 'X') & chr == chrom & CN == 'neutral' & nMinor == 0)
				}
			}
			windows <- IRanges(start = sample_chrom_segs$startpos, end = sample_chrom_segs$endpos)
			mcols(windows)$Sample <- sample_chrom_segs$Sample
			overlap <- findOverlaps(query = ranges(ref_genome), subject = windows)
			# get non-overlapping ref regions for plotting purposes
			non_overlap <- ref_genome[!ranges(ref_genome) %over% windows, ]
			c <- ref_genome[queryHits(overlap)]
			d <- windows[subjectHits(overlap)]
			# Get the metadata columns
			mcols(c) <- cbind(mcols(c), mcols(d))
			# The IRanges 'countOverlaps' doesn't work here, some samples may be counted twice
			overlap_counts <- distinct(as.data.frame(c)) %>% count(seqnames, start, end, strand, width) %>% bind_rows(as.data.frame(non_overlap)) %>%
								select(-strand) %>% replace(is.na(.), 0) %>% arrange(start) 
			# Get distinct rows then count total for each range
			if (cn %in% c('gain', 'loss')) {
				result <- cbind.data.frame(chrom, overlap_counts$start, overlap_counts$end, overlap_counts$width, (overlap_counts$n/totsamples), str_to_title(cn), overlap_counts$n)
			} else if (cn == 'cn-loh') {
				result <- cbind.data.frame(chrom, overlap_counts$start, overlap_counts$end, overlap_counts$width, (overlap_counts$n/totsamples), cn, overlap_counts$n)
			}
			colnames(result) <- c("Group", "Start", "End", "Width", "Value", "CN", "Count")
			if (cn == "loss") {
				result$Value <- result$Value * -1
			}
			result <- result %>% group_by(Group) %>% mutate(Subgroup = 1:n(), .after = Group)
			if (nrow(cn_counts) == 0) {
				cn_counts <- result
			} else {
				cn_counts <- rbind.data.frame(cn_counts, result)
			}
		}
	}
	return(cn_counts)
}


########## Main ##########


# Tile the genome into 1Mb regions

names(chrSizes) <- chrnames
bins <- tileGenome(chrSizes, tilewidth = 1000000, cut.last.tile.in.chrom = T)


# Read in sample2sex file

sample_sex <- read.table(sample2sex_list, stringsAsFactors = F, header = F, sep = "\t")
colnames(sample_sex) <- c("Sample", "Sex")

# Read in purity/ploidy file

sample_ploidy <- read.table(ploidy_list, stringsAsFactors = F, header = F, sep = "\t")
colnames(sample_ploidy) <- c("Sample", "Purity", "Ploidy")

# Read in all segment files

segfile_list <- read.table(filelist, stringsAsFactors = F, header = F)
totsamples <- nrow(segfile_list)

print(paste("Samples", totsamples))

segments <- data.frame()

for (segfile in segfile_list$V1) {
	print(paste("Reading file", segfile))
	segs <- read.table(segfile, header = T, sep = "\t", comment.char = "", check.names = F)
#	segs <- read.table(segfile, header = T, sep = "\t", comment.char = "")
#	print(head(segs))
	segs$chr <- sub("chr", "", segs$chr)
	if (nrow(segments) == 0) {
		segments <- segs
	} else {
		segments <- rbind(segments, segs)
	}
}

# Add patient sex for chrX calls

#segments <- segments %>% rename(Sample = sample)
segments <- segments %>% rename(Sample = sample) %>% 
		left_join(sample_sex, by = "Sample") %>%
		left_join(sample_ploidy, by = "Sample")

#     Sample chr  startpos    endpos nMajor nMinor Sex Purity  Ploidy
# 1 PD56546c   1    826681  43198448      2      2   F   0.71 3.73206
# 2 PD56546c   1  43198547  43209986      2      1   F   0.71 3.73206
# 3 PD56546c   1  43210107 156782110      2      2   F   0.71 3.73206
# 4 PD56546c   1 156782198 162020316      2      1   F   0.71 3.73206

# Call CN gains and losses and add segment size

segments <- segments %>% mutate(CN = ifelse(chr == "X" & Sex == "M" & 0.5 * round(Ploidy) > nMajor + nMinor, "loss",
										ifelse(chr == "X" & Sex == "M" & 0.5 * round(Ploidy) < nMajor + nMinor, "gain",
										ifelse(chr == "X" & Sex == "M" & 0.5 * round(Ploidy) == nMajor + nMinor, "neutral",
										ifelse(round(Ploidy) == nMajor + nMinor, "neutral",
										ifelse(round(Ploidy) > nMajor + nMinor, "loss", "gain")))))) %>%
				mutate(Size = endpos - startpos + 1)

#segments
#    Sample chr  startpos    endpos nMajor nMinor Sex Purity   Ploidy      CN
#1 PD52375a   1     69511 121568263      0      0   F   0.26 1.965307    loss
#2 PD52375a   1 143544192 223712842      2      2   F   0.26 1.965307    gain
#3 PD52375a   1 223712910 248918428      2      1   F   0.26 1.965307    gain
#4 PD52375a   2     41509 242004549      1      1   F   0.26 1.965307 neutral
#5 PD52375a   3    197630 198038561      1      1   F   0.26 1.965307 neutral
#6 PD52375a   4     85813 190025891      1      1   F   0.26 1.965307 neutral
#       Size
#1 121498753
#2  80168651
#3  25205519
#4 241963041
#5 197840932
#6 189940079
#q()

##### Make frequency plot for CN gains and losses #####

# Generate counts for 1Mb regions for each chrom

cn_counts <- get_counts(segments, c('gain', 'loss'))
cn_counts$Group <- factor(cn_counts$Group, levels = chrnames)

# Output counts per 1Mb regions and segments with purity, ploidy and CN columns

write.table(file = paste0(outfile, "_CNfreq.tsv"), as.data.frame(cn_counts), sep = "\t", quote = F, row.names = F)
write.table(file = paste0(outfile, "_segments.tsv"), segments, sep = "\t", quote = F, row.names = F)

# Draw plot

wsize = "1Mb"
minsize_mb = 0

if (minsize > 0) {
	minsize_mb <- sub("0+$", "", (minsize / 1000000))
}

which = ifelse(minsize == 0, "all", paste0("min. size ", minsize_mb, "Mb"))

plot_freq(cn_counts, paste0(outfile, "_CNfreq.pdf"), which)



##### Frequency plot for cn-LOH #####

# Generate counts for 1Mb regions for each chrom

cn_counts_loh <- get_counts(segments, c('cn-loh'))
cn_counts_loh$Group <- factor(cn_counts_loh$Group, levels = chrnames)

# Output counts per 1Mb regions and segments with purity, ploidy and CN columns

write.table(file = paste0(outfile, "_cn-loh.tsv"), as.data.frame(cn_counts_loh), sep = "\t", quote = F, row.names = F)

# Draw plot

plot_cn_loh(cn_counts_loh, paste0(outfile, "_cn-loh.pdf"), which)



