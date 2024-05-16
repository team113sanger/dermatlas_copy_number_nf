#!/usr/bin/env Rscript

################################################################################################################
## The goal of the script get_wide_peaks.R is to generate a list of GISTIC2 wide peaks that can be considered ##
## in downstream analyses. Taking a GISTIC2 all_lesions file and an ASCAT segments file, this script will do  ##
## the following:                                                                                             ##
##                                                                                                            ##
## @ Calculate the peak size of each wide peak.                                                               ##
## @ Filter out wide peaks that do not satisfy a given residual q-value threshold.                            ##
## @ Assess the concordance between GISTIC2 and ASCAT calls.                                                  ##
## @ Generate per-wide peak sample lists to be used in downstream scritps.                                    ##
################################################################################################################


###############################
####---- Load packages ----####
###############################

(library(Matrix))
(library(expm))
(library(DescTools))
(library(optparse))
(library(stringr))
(library(dplyr))
(library(tidyr))
(library(reshape2))
library(valr)


#################################
####---- Parse arguments ----####
#################################

progname <- "gistic2_filter.R"

option_list <- list(
    make_option(c("-p", "--prefix"), 
        dest = "prefix",
        action = "store",
        type = "character", 
        default = NA, 
        help = "Output file prefix"),
    make_option(c("-g", "--gistic-all-lesions-file"), 
        dest = "gistic_all_lesions",
        action = "store", 
        type = "character", 
        default = NA, 
        help = "Path to a GISTIC2 all_lesions file."),
    make_option(c("-a", "--ascat-segments-file"), 
        dest = "ascat_segments",
        action = "store", 
        type = "character", 
        default = NA, 
        help = "Path to an ASCAT segments file."),
    make_option(c("-q", "--residual-q-value-cutoff"), 
        dest = "res_q_value",
        action = "store", 
        type = "double", 
        default = NA, 
        help = "Residual q-value threshold."),
    make_option(c("-d", "--difficult-regions-file"), 
        dest = "diff_regions",
        action = "store", 
        type = "character", 
        default = NA, 
        help = "Path to a BED file with region problematic regions"),
    make_option(c("-o", "--output-dir"), 
        dest = "output_path",
        action = "store", 
        type = "character", 
        default = NA, 
        help = "Output directory.")
)

parser <- OptionParser(usage = paste0(progname, " [options] --prefix output_prefix --gistic-all-lesions-file path/to/file --ascat-segments-file path/to/file --residual-q-value-cutoff 0.1 --difficult-regions-file path/to/bedfile --output-dir path/to/output"), 
                       option_list = option_list)

arguments <- parse_args(parser, positional_arguments = 0)
prefix <- arguments$options$prefix
gistic.all.lesions <- arguments$options$gistic_all_lesions
ascat.segments <- arguments$options$ascat_segments
res.q.value.cutoff <- arguments$options$res_q_value
output.path <- arguments$options$output_path
diff_regions_file <- arguments$options$diff_regions

# Check required arguments

if(is.na(prefix)) stop("Provide an output file prefix.")
if(is.na(gistic.all.lesions)) stop("Provide a GISTIC2 all_lesions file.")
if(is.na(ascat.segments)) stop("Provide a path to an ASCAT segments file.")
if(is.na(res.q.value.cutoff)) {
    warning("No residual q-value threshold has been provided. Using 0.1 as default.")
    res.q.value.cutoff <- 0.1
} 
if(is.na(output.path)) stop("Provide a path for the output directory.")

# Check that input files exist

if(!file.exists(gistic.all.lesions)) stop("The GISTIC file does not exist.")
if(!file.exists(ascat.segments)) stop("The ASCAT segments file provided does not exist.")
if(!dir.exists(output.path)) stop("The output directory provided does not exist.")


##################################
####---- Read input files ----####
##################################

all_lesions <- read.table(gistic.all.lesions, header = TRUE, sep = "\t")
segments <- read.table(ascat.segments, header = TRUE, sep = "\t")
segments$chr <- paste0("chr", segments$chr)

# Checking for problems with ASCAT segment file

if (nrow(segments[is.na(segments$CN),]) > 0) {
	stop("Error: NAs found in the segments file. Exiting.")
}


###########################################
####---- Process all_lesions table ----####
###########################################

all_lesions$X <- NULL

# Remove the "(" and everything after it [e.g. (probes 1522:1538)].

all_lesions$Wide.Peak.Limits <- gsub("\\(.*","", all_lesions$Wide.Peak.Limits)

# Remove "Actual Copy Change Given" section from dataframe.

all_lesions <- all_lesions[all_lesions$Amplitude.Threshold != "Actual Copy Change Given",]

# Keep significant CNA events (i.e. those whose residual q-value <= 0.1).
#all_lesions <- all_lesions %>%
#                rename("residual.q.values" = "Residual.q.values.after.removing.segments.shared.with.higher.peaks") %>%
#                filter(residual.q.values <= res.q.value.cutoff)

# Rename q-value column

all_lesions <- all_lesions %>%
                rename("residual.q.values" = "Residual.q.values.after.removing.segments.shared.with.higher.peaks")


###########################################################
####---- Compare samples in GISTIC and ASCAT files ----####
###########################################################

ascat_sample_check <- sort(unique(segments$Sample))

gistic_sample_check <- sort(colnames(all_lesions)[10:ncol(all_lesions)])

if (! identical(ascat_sample_check, gistic_sample_check)) {
	stop("Error: Samples in the ASCAT segment file and GISTIC all_lesions file are not the same. Exiting")
}


##########################################################
####---- Generate a wide peak x sample data frame ----####
##########################################################

all_lesions_filt <- all_lesions %>% select(Unique.Name, Wide.Peak.Limits, residual.q.values, c(10:ncol(all_lesions))) %>%
		mutate("gistic_peak" = Wide.Peak.Limits, .before = "Wide.Peak.Limits") %>%
		separate(Wide.Peak.Limits, c("chrom", "start", "end")) %>%
		#separate(Wide.Peak.Limits, sep = ":", c("chrom", "range")) %>%
		#separate(range, sep = "-", c("start", "end")) %>%
		mutate_at(c("start", "end"), as.numeric)

#### Add a column with proprortion of overlap with difficult regions

if (!is.na(diff_regions_file)) {
	difficult_reg <- read.table(diff_regions_file, header = F, sep = "\t", stringsAsFactors = F)
	colnames(difficult_reg) <- c("chrom", "start", "end")
	peak_reg <- all_lesions_filt %>% select("chrom", "start", "end")
	peak_reg_cov <- bed_coverage(peak_reg, difficult_reg)
	all_lesions_filt <- all_lesions_filt %>%
		left_join(., peak_reg_cov, by = c("chrom", "start", "end"), relationship = "many-to-many") %>%
		relocate(.frac, .after = "residual.q.values") %>%
		rename("difficult_frac" = .frac ) %>%
		relocate(.len, .after = "end") %>%
		rename("peak_size" = .len ) %>%
		select(-.ints, -.cov) %>%
		arrange(residual.q.values) %>%
		filter(duplicated(Unique.Name) == FALSE)
}

#### Add a column with gain, loss, neutral for comparison to ASCAT

for (i in 9:ncol(all_lesions_filt)) {
    for (g in 1:nrow(all_lesions_filt)) {
		if (all_lesions_filt[g, i] == 0) {
			all_lesions_filt[g, i] <- "neutral"
		} else if (grepl("Amp", all_lesions_filt[g, "Unique.Name"])) {
			if (all_lesions_filt[g, i] > 0) {
				all_lesions_filt[g, i] = "gain"
			}
        } else {
			if (all_lesions_filt[g, i] > 0) {
				all_lesions_filt[g, i] = "loss"
			}
		}
	}
}



##################################################################
####---- Assess overlap between GISTIC2 and ASCAT results ----####
##################################################################

# Input format of parsed ASCAT calls:
# Sample  chr     startpos        endpos  nMajor  nMinor  Sex     Purity  Ploidy  CN      Size
# PD42171a        1       69511   121568263       2       2       F       0.51    3.89959788554496        neutral 121498753

# Melt the data frame to create a data frame with one peak per sample per row

sort(all_lesions_filt$Unique.Name)

gistic_df <- melt(all_lesions_filt, id.vars = c("Unique.Name", "gistic_peak", "chrom", "start", "end", "residual.q.values", "difficult_frac", "peak_size")) %>%
		rename("gistic_name" = "Unique.Name", "sample" = "variable", "gistic_call" = "value") %>%
		filter(gistic_call != "neutral")

gistic_df["match"] <- NA
gistic_df["fraction_overlap"] <- NA
gistic_df["ascat_start"] <- NA
gistic_df["ascat_end"] <- NA
gistic_df["ascat_size"] <- NA

samples_per_peak <- data.frame()

for (peak in unique(gistic_df$gistic_name)) {
	gistic_samples <- gistic_df %>% filter(gistic_name == peak) %>% select(sample) %>% unique()
	gistic_coords <- gistic_df %>% filter(gistic_name == peak) %>% select(chrom, start, end) %>% filter(row_number() == 1)
	gistic_call <- gistic_df %>% filter(gistic_name == peak) %>% select(gistic_call) %>% filter(row_number() == 1)
	gistic_range <- as.numeric(c(gistic_coords[1, "start"], gistic_coords[1, "end"]))
	ascat_compare <- segments %>% filter(chr == gistic_coords[1, "chrom"] & CN == gistic_call[1, 1] & Sample %in% gistic_samples$sample)

	gistic_sample_list <- paste0(gistic_samples$sample, collapse = ",")
	samples_per_peak <- rbind(samples_per_peak, c(peak, gistic_sample_list))

	for (i in 1:nrow(ascat_compare)) {
		ascat_range <- as.numeric(c(ascat_compare[i, "startpos"],  ascat_compare[i, "endpos"]))
		ascat_sample <- ascat_compare[i, "Sample"]
        if(gistic_range %overlaps% ascat_range) {
            over <- min(gistic_range[2], ascat_range[2]) - max(gistic_range[1], ascat_range[1]) + 1
            over <- over / (gistic_range[2] - gistic_range[1] + 1)
            if (over > 0.25) {
				found <- gistic_df[gistic_df$gistic_name == peak & gistic_df$sample == ascat_sample, "fraction_overlap"]
				check <- gistic_df[gistic_df$gistic_name == peak & gistic_df$sample == ascat_sample,]
				# If another overlap found previously and the overlap is smaller, use the current overlapping segment
				if (is.na(found) | (!(is.na(found)) & found < over)) {
					gistic_df[gistic_df$gistic_name == peak & gistic_df$sample == ascat_sample, "fraction_overlap"] <- over
					gistic_df[gistic_df$gistic_name == peak & gistic_df$sample == ascat_sample, "match"] <- "Match"
					gistic_df[gistic_df$gistic_name == peak & gistic_df$sample == ascat_sample, "ascat_start"] <- ascat_range[1]
					gistic_df[gistic_df$gistic_name == peak & gistic_df$sample == ascat_sample, "ascat_end"] <- ascat_range[2]
					gistic_df[gistic_df$gistic_name == peak & gistic_df$sample == ascat_sample, "ascat_size"] <- ascat_range[2] - ascat_range[1] + 1
				}

			}
        }
    }

}

gistic_df[is.na(gistic_df)] <- "No_match"

###################################
####---- Summarise results ----####
###################################

# Add samples and genes in each peak

gistic_df <- gistic_df[order(gistic_df$gistic_name),]
colnames(samples_per_peak) <- c("gistic_name", "samples")
head(samples_per_peak)

comparison_summary <- gistic_df %>% group_by(gistic_name, gistic_peak, residual.q.values, chrom, start, end, gistic_call, difficult_frac, peak_size) %>% 
    summarise(ascat_agree = sum(ifelse(match == "Match", 1, 0)),
              ascat_disagree = sum(ifelse(match == "No_match", 1, 0))) %>%
    mutate(concordance = ascat_agree / (ascat_agree + ascat_disagree)) %>%
	mutate(qc_status = ifelse(residual.q.values < 0.1 & concordance >= 0.75 & peak_size > 100000 & difficult_frac < .4, "PASS", "FAIL")) %>%
	mutate(qc_and_max_10Mb = ifelse(qc_status == "PASS" & peak_size <= 10000000, "PASS", "FAIL")) %>%
    arrange(gistic_name) %>% left_join(., samples_per_peak, by = "gistic_name") %>%
	data.frame()

####################################
####---- Write output files ----####
####################################

# Summary by peak

write.table(data.frame(comparison_summary), file = paste0(prefix, "_gistic_cohort_summary.tsv"), sep = "\t",  row.names = F, quote = F)

# Per peak per sample QC

write.table(data.frame(gistic_df), file = paste0(prefix, "_gistic_sample_summary.tsv"), sep = "\t",  row.names = F, quote = F)

# Samples with gain/loss in gain/loss wide peaks

#samples_per_peak

# Summary by gene (user gene list)


