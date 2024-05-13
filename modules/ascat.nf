process RUN_ASCAT_EXOMES {
    publishDir "${params.OUTDIR}", mode: 'copy'
    // container: 
    
    input: 
    tuple val(metadata), path(normbam), path(tumbam)
    path(outdir)
    path(project_dir)
    
    output:
    // tuple val(meta), path("QC_*.tsv"),                   emit: qc_metrics
    tuple val(metadata), path("ASCAT_estimates_*.tsv"),      emit: estimates
    // tuple val(meta), path("gistic2_segs_*.tsv"),         emit: gistic_inputs
    // tuple val(meta), path("*.png"),                       emit: plots
    // tuple val(meta), path("ASCAT_objects.Rdata").         emit:rdata
    // tuple val(meta), path("*alleleFrequencies_chr*.txt"),      emit: allelefreqs
    // tuple val(meta), path("*BAF.txt"),                         emit: bafs
    // tuple val(meta), path("*cnvs.txt"),                        emit: cnvs
    // tuple val(meta), path("*LogR.txt"),                        emit: logrs
    // tuple val(meta), path("*metrics.txt"),                     emit: metrics
    // tuple val(meta), path("*purityploidy.txt"),                emit: purityploidy
    tuple val(metadata), path("*segments.txt"),                    emit: segments

    script:
    def tum = "${metadata.tumor}"
    def norm = "${metadata.normal}"
    def sexchr = "${metadata.sexchr}"

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
    def prefix = "${metadata.normal}"[1]
    """
    echo stub > ASCAT_estimates_chr1.tsv
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
    tuple val(meta), path(collected_files)
    // path(sample_metadata)

    output:
    tuple val(meta), path("ascat_stats.tsv"), path("samples2sex.tsv"), path("ascat_low_qual.list"), path("sample_purity_ploidy.tsv"), emit: ascat_sstats

    script:
    // awk '{print $1"\t"$5"\t"$3}' ascat_stats.tsv  | sed 's/-/\t/' |cut -f 1,3,4 | grep PD | xargs -i basename {} > sample_purity_ploidy.tsv
    // awk '$2<90' ascat_stats.tsv | cut -f 1 -d "-" | cut -f 3 -d "/" >  ascat_low_qual.list
    """
    echo summarise_ascat_estimates.pl $collected_files > ascat_stats.tsv
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
    tuple val(meta), path(segfiles_list)
    tuple val(meta), path(stats), path(sample_sex), path(unuser), path(purity_ploidy)

    output:
    tuple val(meta), path("*_cn-loh.pdf"), path("*_cn-loh.tsv")
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
