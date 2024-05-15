process RUN_ASCAT_EXOMES {
    publishDir "${params.OUTDIR}", mode: 'copy'
    container 'gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/ascat/feature/import-dockerisation:629e43c0'
    
    input: 
    tuple val(meta), path(normbam), path(tumbam)
    path(outdir)
    path(project_dir)
    
    output:
    tuple val(meta), path("QC_*.tsv"),                     emit: qc_metrics
    tuple val(meta), path("ASCAT_estimates_*.tsv"),        emit: estimates
    tuple val(meta), path("gistic2_segs_*.tsv"),           emit: gistic_inputs
    tuple val(meta), path("*.png"),                        emit: plots
    tuple val(meta), path("ASCAT_objects.Rdata"),          emit:rdata
    tuple val(meta), path("*alleleFrequencies_chr*.txt"),  emit: allelefreqs
    tuple val(meta), path("*BAF.txt"),                     emit: bafs
    tuple val(meta), path("*cnvs.txt"),                    emit: cnvs
    tuple val(meta), path("*LogR.txt"),                    emit: logrs
    tuple val(meta), path("*metrics.txt"),                 emit: metrics
    tuple val(meta), path("*purityploidy.txt"),            emit: purityploidy
    tuple val(meta), path("*segments.txt"),                emit: segments

    script:
    def tum = "${meta.tumor}"
    def norm = "${meta.normal}"
    def sexchr = "${meta.sexchr}"
    """
    run_ascat_exome.R \
    --tum_bam $tumbam \
    --norm_bam $normbam \
    --tum_name $tum \
    --norm_name $norm \
    --sex $sexchr \
    --outdir $tum-$norm \
    --project_dir $project_dir
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
    input: 
    path(collected_files)

    output:
    tuple path("ascat_stats.tsv"), path("samples2sex.tsv"), path("ascat_low_qual.list"), path("sample_purity_ploidy.tsv"), emit: ascat_sstats

    script:
    """
    echo summarise_ascat_estimates.pl $collected_files > ascat_stats.tsv
    awk '{print \$1"\t"\$5"\t"\$3}' ascat_stats.tsv  | sed 's/-/\t/' |cut -f 1,3,4 | grep PD | xargs -i basename {} > sample_purity_ploidy.tsv
    awk '\$2<90' ascat_stats.tsv | cut -f 1 -d "-" | cut -f 3 -d "/" >  ascat_low_qual.list
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
    input:
    path(segfiles_list)
    tuple path(stats), path(sample_sex), path(ascat_low_qual), path(purity_ploidy)

    output:
    tuple path("*_cn-loh.pdf"), path("*_cn-loh.tsv")
    script:
    """
    echo plot_ascat_cna_and_loh.R \
    $segfiles_list \
    $purity_ploidy \
    $sample_sex \
    $prefix
    """
    stub:
    """
    echo stub > x_cn-loh.pdf
    echo stub > x_cn-loh.tsv
    """


}
