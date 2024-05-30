process RUN_GISTIC2 {
    label 'process_high'
    publishDir "${params.OUTDIR}/GISTIC2", mode: 'copy'
    container "gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/gistic2/feature/import_dockerisation:842c9515"
    
    input: 
    path(segment_file)
    path(refgenefile)

    output:
    path("all_lesions.conf_95.txt"), emit: lesions
    path("broad_significance_results.txt"), emit: broad
    path("broad_values_by_arm.txt"), emit: arms
    path("*.png"), emit: plots
    path("*.pdf"), emit: pdfs
    path("*.mat"), emit: mats
    path("*.txt"), emit: tables
    path(segment_file), emit: segment_file
    
    script:
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

process FILTER_GISTIC2_CALLS{
    label 'process_medium'
    publishDir "${params.OUTDIR}/GISTIC2_ASSESS", mode: 'copy'
    container "gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/gistic_assess/feature/nf_image:fe793813"
    input:
    path(segments)
    path(lesions)
    path(difficult_regions)
    val(prefix)

    output:
    path("*_gistic_sample_summary.tsv"), emit: cs
    path("*_gistic_cohort_summary.tsv"), emit: ss

    script:
    """
    /opt/repo/gistic2_filter.R \
    --prefix $prefix \
    --gistic-all-lesions-file $lesions \
    --ascat-segments-file $segments \
    --residual-q-value-cutoff 0.1 \
    --output-dir . \
    -d $difficult_regions

    """
    stub: 
    """
    echo stub > QC_gistic_sample_summary.tsv
    echo stub > QC_gistic_cohort_summary.tsv
    """

}