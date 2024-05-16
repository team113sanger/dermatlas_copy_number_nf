The *_ASCAT.maf files contain only variants that overlap with
ASCAT segments that are called as CN gain or loss. The MAF lines
are the same as the original, but additional columns added showing
information about segments that overlap each variant. 

ASCAT_Sample    # sample ID
ASCAT_chr       # segment chrom
ASCAT_startpos  # segment start
ASCAT_endpos    # segment end
ASCAT_nMajor    # major allele count 
ASCAT_nMinor    # minor allele count
ASCAT_Sex       # inferred patient sex
ASCAT_Purity    # estimated tumour purity from ASCAT
ASCAT_Ploidy    # estimated tumour ploidy from ASCAT
ASCAT_CN        # interpreted CN call: gain/loss/neutral
ASCAT_Size      # ASCAT segment size
Difficult_regions_overlap   # fraction of ASCAT segment overlapping with GIAB difficult region

GIAB = Genome In A Bottle. Please see:

https://www.nist.gov/programs-projects/genome-bottle

This consortium provides benmarking data sets, reference, methods for variant calling,
validation, and development.  "Difficult regions" are genomic regions considered to be 
problematic for analyses such as variant calling. For GISIC2 wide peaks, we applied a cutoff
of wide peaks to KEEP if the overlap fraction < 0.4. It is recommended for ASCAT segments that 
the ASCAT_Size and Difficult_regions_overlap be considered when deciding on reliability of 
a CN call. (Generally, smaller segments are more likely to be false positives; removing/filtering 
segments < 100kb in size is a good start).




