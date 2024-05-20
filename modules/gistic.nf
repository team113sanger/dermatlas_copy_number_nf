process RUN_GISTIC {
    container: "asntech/gistic2:v2.0.23"
    input: 
    tuple val(meta), path(SEGFILE)
    path(refgenefile)
    
    output:
    path("all_lesions.conf_95.txt")
    
    script:
    def f = 0
    """
    gp_gistic2_from_seg \
    -b MIN_${f} \
    -seg min${f}_segments.tsv \
    -refgene $refgenefile \
    -genegistic 1 \
    -smallmem 1 \
    -broad 1 \
    -brlen 0.75 \
    -conf 0.95 \ 
    -armpeel 1 \
    -savegene 1 \
    -gcm extreme \
    -v 20 \
    -ta 0.25 \
    -td 0.25
    """

    stub: 
    """
    echo stub > all_lesions.conf_95.txt
    """

    
}

process FILTER_GISTIC_CALLS{
    input:

    path(difficult_regions)

    output:
    tuple path("*_gistic_sample_summary.tsv"), path("*_gistic_cohort_summary.tsv")

    script:
    """
    gistic2_filter.R
    ${PROJECTDIR} \
    all_lesions.conf_95.txt \
    ${ASCAT_SEGS} \
    QC \
    $difficult_regions
    """
    script:
    """
    """
    stub: 
    """
    echo stub > QC_gistic_sample_summary.tsv
    echo stub > QC_gistic_cohort_summary.tsv
    """

}