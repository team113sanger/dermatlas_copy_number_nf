process RUN_GISTIC {
    // publishDir ""
    container "gistic2:latest"
    
    input: 
    path(segment_file)
    path(refgenefile)
    
    output:
    path("all_lesions.conf_95.txt")
    
    script:
    def f = 0
    """
    /opt/repo/gp_gistic2_from_seg \
    -b . \
    -seg $segment_file \
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
    path(PREFIX)
    path(LESIONS)
    path(SEGMENTS)

    output:
    tuple path("*_gistic_sample_summary.tsv"), path("*_gistic_cohort_summary.tsv")

    script:
    """
    /opt/repo/gistic2_filter.R \
    --prefix ${PREFIX} \
    --gistic-all-lesions-file ${LESIONS} \
    --ascat-segments-file ${SEGMENTS} \
    --residual-q-value-cutoff 0.1 \
    --output-dir $PWD \
    -d ${DIFF}

    """
    stub: 
    """
    echo stub > QC_gistic_sample_summary.tsv
    echo stub > QC_gistic_cohort_summary.tsv
    """

}