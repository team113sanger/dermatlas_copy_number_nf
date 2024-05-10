library(dplyr)
library(valr)

# Ascat annotated file format
# Sample	chr	startpos	endpos	nMajor	nMinor	Sex	Purity	Ploidy	CN	Size
# PD56526a	1	826681	248918428	1	1	M	0.76	2.07625432667259	neutral	248091748
# PD56526a	2	41509	11344147	1	1	M	0.76	2.07625432667259	neutral	11302639
# PD56526a	2	11446553	28850976	1	0	M	0.76	2.07625432667259	loss	17404424

# Hugo_Symbol	Center	NCBI_Build	Chromosome	Start_Position	End_Position	Variant_Classification	Variant_Type	Reference_Allele	Tumor_Seq_Allele2	Tumor_Sample_Barcode
# RPS6KA1	Sanger	GRCh38	chr1	26560781	26560781	Missense_Mutation	SNP	T	C	PD56526a
# NEK2	Sanger	GRCh38	chr1	211674485	211674485	Missense_Mutation	SNP	C	T	PD56526a

args <- commandArgs(trailingOnly = TRUE) 

maf_file <- args[1]
cn_file <- args[2]
outfile <- args[3]
diff_regions_file <- args[4]

# Read MAF file

vars <- read.table(maf_file, header = T, sep = "\t")

# Read ASCAT file

cn <- read.table(cn_file, header = T, sep = "\t")

# add 'chr' to ascat file

cn$chr <- sub("^", "chr", cn$chr)
cn <- cn %>% filter(CN != "neutral")

maf_with_cn <- data.frame(matrix(nrow = 0, ncol = 83))
colnames(cn) <- sub("^", "ASCAT_", colnames(cn))

colnames(maf_with_cn) <- c(colnames(vars), colnames(cn), "Difficult_region_overlap")

if (!is.na(diff_regions_file)) {
	difficult_reg <- read.table(diff_regions_file, header = F, sep = "\t", stringsAsFactors = F)
	colnames(difficult_reg) <- c("chrom", "start", "end")
}

# Check overlap and non-neutral CN segments

for (line in 1:nrow(vars)) {
	chr <- vars[line, "Chromosome"]
	sample <- vars[line, "Tumor_Sample_Barcode"]
	cn_segs <- cn %>% filter(ASCAT_chr == chr & ASCAT_Sample == sample)
	if (nrow(cn_segs) > 0) {
		for (cn_line in 1:nrow(cn_segs)) {
			over <- min(vars[line, "End_Position"], cn_segs[cn_line, "ASCAT_endpos"]) - max(vars[line, "Start_Position"], cn_segs[cn_line, "ASCAT_startpos"]) + 1
			seg_reg <- cn_segs[cn_line, c("ASCAT_chr", "ASCAT_startpos", "ASCAT_endpos")]
			colnames(seg_reg) <- c("chrom", "start", "end")
			seg_cov <- "NA"
			if (over > 0) {
				if (!is.na(diff_regions_file)) {
					seg_cov <- bed_coverage(seg_reg, difficult_reg) %>% select(.frac) %>%
								rename("Difficult_regions_overlap" = ".frac")
				}
				
				maf_with_cn <- rbind(maf_with_cn, cbind(vars[line, ] ,cn_segs[cn_line, ], seg_cov))
			}
		}
	}
}

write.table(maf_with_cn, file = outfile, quote = F, sep = "\t", row.names = F)
