process RUN_ASCAT_EXOMES {
    publishDir "${params.outdir}/ASCAT/${meta.tumor}-${meta.normal}", mode: params.publish_dir_mode
    container 'gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/ascat:0.5.0'
    input: 
    tuple val(meta), path(normbam), path(normindex), path(tumbam), path(tumindex)
    val(outdir)
    path(genome)
    path(baits) 
    path(per_chrom_dir)
    path(gc_file)
    path(rt_file)

    
    output:
    tuple val(meta), path("QC_*.tsv"),                     emit: qc_metrics
    tuple val(meta), path("ASCAT_estimates_*.tsv"),        emit: estimates
    tuple val(meta), path("gistic2_segs_*.tsv"),           emit: gistic_inputs
    tuple val(meta), path("*.png"),                        emit: plots
    tuple val(meta), path("ASCAT_objects.Rdata"),          emit: rdata
    tuple val(meta), path("*alleleFrequencies_chr*.txt"),  emit: allelefreqs
    tuple val(meta), path("*BAF.txt"),                     emit: bafs
    tuple val(meta), path("*LogR.txt"),                    emit: logrs
    tuple val(meta), path("*segments.txt"),                emit: segments
    tuple val(meta), path("*segments_raw.txt"),            emit: raw_segs


    script:
    def norm = "$meta.normal"
    def tum = "$meta.tumor"
    def sexchr = "$meta.sexchr"

    """
    /opt/repo/run_ascat_exome_nf.R \
    --tum_bam $tumbam \
    --norm_bam $normbam \
    --norm_name $norm \
    --tum_name $tum \
    --sex $sexchr \
    --outdir $tum-$norm \
    --ref_file $genome \
    --bed_file $baits \
    --per_chrom $per_chrom_dir \
    --gc_file $gc_file \
    --rt_file $rt_file 
    """
    
    stub:
    def prefix = "${meta.tumor}"
    def pair = "${meta.pair_id}"
    """
    echo stub > ASCAT_estimates_${pair}.tsv
    echo stub > QC_${pair}.tsv
    echo stub > gistic2_segs_${pair}.tsv
    echo stub > ASCAT_objects.Rdata
    echo stub > ${prefix}.after_correction.gc_rt.test.tumour.germline.png
    echo stub > ${prefix}.after_correction.gc_rt.test.tumour.tumour.png
    echo stub > ${prefix}.before_correction.test.tumour.germline.png
    echo stub > ${prefix}.before_correction.test.tumour.tumour.png
    echo stub > ${prefix}.cnvs.txt
    echo stub > ${prefix}.metrics.txt
    echo stub > ${prefix}.normal_alleleFrequencies_chr21.txt
    echo stub > ${prefix}.normal_alleleFrequencies_chr22.txt
    echo stub > ${prefix}.purityploidy.txt
    echo stub > ${prefix}.segments.txt
    echo stub > ${prefix}.tumour.ASPCF.png
    echo stub > ${prefix}.tumour.sunrise.png
    echo stub > ${prefix}.tumour_alleleFrequencies_chr21.txt
    echo stub > ${prefix}.tumour_alleleFrequencies_chr22.txt
    echo stub > ${prefix}.tumour_normalBAF.txt
    echo stub > ${prefix}.tumour_normalLogR.txt
    echo stub > ${prefix}.tumour_tumourBAF.txt
    echo stub > ${prefix}.tumour_tumourLogR.txt
    """
}


process SUMMARISE_ASCAT_ESTIMATES {
    label 'process_medium'
    publishDir "${params.outdir}/ASCAT/${params.release_version}/${meta.analysis_type}", mode: params.publish_dir_mode
    container 'gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/ascat:0.5.0'
    
    input: 
    tuple val(meta), path(collected_files)
    
    output:
    path("ascat_stats.tsv"),                        emit: ascat_sstats
    path("ascat_low_qual.list"),                    emit: low_quality
    path("sample_purity_ploidy.tsv"),               emit: purity

    script:
    """
    /opt/repo/summarise_ascat_estimate.R \
    --estimates_path .
    """
    
    stub:
    """
    echo stub > samples2sex.tsv
    echo stub > ascat_stats.tsv
    echo stub > ascat_low_qual.list
    echo stub > sample_purity_ploidy.tsv
    """

}


process CREATE_FREQUENCY_PLOTS {
    label 'process_medium'
    publishDir "${params.outdir}/ASCAT/${params.release_version}/${meta.analysis_type}/${meta.plot_dir}", mode: params.publish_dir_mode
    container 'gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/ascat:0.5.0'

    input:
    tuple val(meta), path(segfiles_list)
    path(purity_ploidy)
    path(sample_sex)
    val(cohort_prefix)

    output:
    tuple val(meta), path("*_cn-loh.tsv"), emit: table
    tuple val(meta), path("*_cn-loh.pdf"), emit: plot
    tuple val(meta), path("*_CNfreq.tsv"), emit: cn_freqs
    tuple val(meta), path("*_CNfreq.pdf"), emit: cn_pdf
    tuple val(meta), path("*cn-loh_segments.tsv"), emit: loh_segs
    tuple val(meta), path("${cohort_prefix}{,-indep}_segments.tsv"), emit: processed_segments


    script:
    def append_prefix = "$meta.analysis_type" == "one_tumor_per_patient" ? cohort_prefix : cohort_prefix + "-indep"
    """
    /opt/repo/plot_ascat_cna_and_loh.R \
    $segfiles_list \
    $purity_ploidy \
    $sample_sex \
    $append_prefix
    """
    
    stub:
    def append_prefix = "$meta.analysis_type" == "one_tumour_per_patient" ? cohort_prefix : cohort_prefix + "-indep"
    """
    echo stub > x_cn-loh.pdf
    echo stub > x_cn-loh.tsv
    echo stub > x_CNfreq.tsv
    echo stub > x_CNfreq.pdf
    echo stub > xcn-loh_segments.tsv
    echo stub > "${append_prefix}_segments.tsv"
    """


}

process EXTRACT_GOODNESS_OF_FIT {
    
    input:
    tuple val(meta), path(txtFile)

    output:
    tuple val(meta), env(goodnessOfFit)

    script:
    // Extract the "Goodness-of-fit" value using grep and cut
    """
    goodnessOfFit=\$(grep 'Goodness-of-fit' ${txtFile} | cut -f2)
    echo "\$goodnessOfFit"
    """
    stub:
    """
    goodnessOfFit=97
    echo "\$goodnessOfFit"
    """
}