process RUN_ASCAT_EXOMES {
    publishDir "${params.OUTDIR}/${meta[1].tumor}-${meta[1].normal}", mode: 'copy'
    container 'gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/ascat/feature/nf_image:d84fa3ad'
    input: 
    tuple val(meta), path(normbam), path(normindex), path(tumbam), path(tumindex)
    path(outdir)
    val(project_dir)
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

    script:
    def tum = "${meta[1].tumor}"
    def norm = "${meta[1].normal}"
    def sexchr = "${meta[1].sexchr}"

    """
    /opt/repo/run_ascat_exome.R \
    --tum_bam $tumbam \
    --norm_bam $normbam \
    --tum_name $tum \
    --norm_name $norm \
    --sex $sexchr \
    --outdir $tum-$norm \
    --ref_file $genome \
    --bed_file $baits \
    --per_chrom $per_chrom_dir \
    --gc_file $gc_file \
    --rt_file $rt_file 
    """
    
    stub:
    def prefix = "${meta[1].tumor}"
    def pair = "${meta[1].pair_id}"
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
    publishDir "${params.OUTDIR}", mode: 'copy'
    container 'gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/ascat/feature/nf_image:d84fa3ad'
    input: 
    path(collected_files)

    output:
    path("ascat_stats.tsv"),                        emit: ascat_sstats
    path("ascat_low_qual.list"),                    emit: low_quality
    path("sample_purity_ploidy.tsv"),               emit: purity

    script:
    """
    /opt/repo/summarise_ascat_estimate.R
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
    publishDir "${params.OUTDIR}", mode: 'copy'
    container 'gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/ascat/feature/nf_image:d84fa3ad'
    input:
    path(segfiles_list)
    path(purity_ploidy)
    path(sample_sex)
    val(cohort_prefix)

    output:
    tuple path("*_cn-loh.pdf"), path("*_cn-loh.tsv")
    script:
    """
    /opt/repo/plot_ascat_cna_and_loh.R \
    $segfiles_list \
    $purity_ploidy \
    $sample_sex \
    $cohort_prefix
    """
    stub:
    """
    echo stub > x_cn-loh.pdf
    echo stub > x_cn-loh.tsv
    """


}
