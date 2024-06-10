include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../modules/ascat.nf'
include { GISTIC2_ANALYSIS } from '../subworkflows/gistic2_analysis.nf'

workflow ANALYSE_COHORT {
    take: 
    ascat_subgroup
    estimates_list
    output_dir
    cohort_prefix
    gistic_refgene_file
    giab_regions
    cutoff
    chrom_arms
    
    main:
    SUMMARISE_ASCAT_ESTIMATES(estimates_list)
    
    analysis_type = ascat_subgroup
    | map{ meta, file, seg -> [analysis_type: meta.analysis_type]}
    
    ascat_subgroup
    | collectFile(keepHeader: true,
                 storeDir: "${params.OUTDIR}/ASCAT/${params.release_version}", 
                 skip: 1){
                 meta, segments, gistic -> 
                 new File("${params.OUTDIR}/ASCAT/${params.release_version}/${meta.analysis_type}").mkdirs()
                 def filename = "${params.OUTDIR}/ASCAT/${params.release_version}/${meta.analysis_type}/combined_segment_file.txt"
                 return [filename, segments]
                 }
    | merge(analysis_type)
    | map { file, meta -> [meta, file]}
    | set { segment_summary }

    ascat_subgroup
    | collectFile(
       storeDir: "${params.OUTDIR}/ASCAT/${params.release_version}"){
       meta, segments, gistic ->
        // new File("${params.release_version}/${meta.analysis_type}").mkdirs()
        def filename = "${params.OUTDIR}/ASCAT/${params.release_version}/${meta.analysis_type}/${meta.analysis_type}_segments.txt"
        return [filename, gistic]}
    | merge(analysis_type)
    | map { file, meta -> [meta, file]}
    | set { gistic_ch }


    ascat_subgroup
    | collectFile(
      storeDir: "${params.OUTDIR}/ASCAT/${params.release_version}"){
           meta, segments, gistic ->
        def filename = "${params.OUTDIR}/ASCAT/${params.release_version}/${meta.analysis_type}/samples2sex.txt"
        [filename, "${meta["tumor"]}\t${meta["sexchr"]}\n"]
    }
    | set { sex2chr_ch }
  

    CREATE_FREQUENCY_PLOTS(segment_summary,
                           SUMMARISE_ASCAT_ESTIMATES.out.purity,
                           sex2chr_ch, 
                           cohort_prefix)

    GISTIC2_ANALYSIS(gistic_ch,
                    CREATE_FREQUENCY_PLOTS.out.processed_segments, 
                    gistic_refgene_file, 
                    giab_regions,
                    cohort_prefix,
                    cutoff,
                    chrom_arms)
    
}