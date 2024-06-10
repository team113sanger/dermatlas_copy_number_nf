process RUN_GISTIC2 {
    label 'process_high'
    publishDir "${params.OUTDIR}/gistic2/${params.release_version}/${meta.analysis_type}", mode: params.publish_dir_mode
    container "gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/gistic2:0.5.0"
    
    input: 
    tuple val(meta), path(segment_file)
    path(refgenefile)

    output:
    tuple val(meta), path("all_lesions.conf_95.txt"), emit: lesions
    tuple val(meta), path("broad_significance_results.txt"), emit: broad
    tuple val(meta), path("broad_values_by_arm.txt"), emit: arms
    tuple val(meta), path("*.png"), emit: plots
    tuple val(meta), path("*.pdf"), emit: pdfs
    tuple val(meta), path("*.mat"), emit: mats
    tuple val(meta), path("*.txt"), emit: tables
    tuple val(meta), path(segment_file), emit: segment_file

    
    script:
    analysis_type = "$meta.analysis_type"
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
    echo stub > broad_significance_results.txt
    echo stub > broad_values_by_arm.txt
    echo stub > test.png
    echo stub > test.pdf
    echo stub > test.mat
    echo stub > test.tsv
    """

    
}

process FILTER_GISTIC2_CALLS{
    label 'process_medium'
    publishDir "${params.OUTDIR}/gistic2/${params.release_version}/${meta.analysis_type}/MIN_0", mode: params.publish_dir_mode
    container "gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/gistic_assess:0.5.0"
    input:
    tuple val(meta), path(segments)
    tuple val(meta), path(lesions)
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

process FILTER_BROAD_GISTIC2_CALLS {
    label 'process_medium'
    publishDir "${params.OUTDIR}/gistic2/${params.release_version}/${params.analysis_type}/MIN_0", mode: params.publish_dir_mode
    container "gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/gistic_assess/feature/broad_sig:579cb2d4"
    input:
    tupple val(meta), path(segments)
    tupple val(meta), path(broad_sig)
    path(by_arms)
    path(arms_file)
    val(cutoff)
    val(prefix)
    
    output:
    path(outfile), emit: cs, optional:true

    script:
    """
    /opt/repo/gistic2_check_broad.R \
    $broad_sig \
    $by_arms \
    $segments \
    $arms_file \
    $cutoff \
    ${cohort_prefix}_gistic_broad_QCcheck.tsv
    """
    stub: 
    """
    echo stub > outfile.tsv
    """

}