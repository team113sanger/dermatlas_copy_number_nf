include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../modules/ascat.nf'
include { GISTIC2_ANALYSIS } from '../subworkflows/gistic2_analysis.nf'

workflow ANALYSE_COHORT {
    take:
    cohort_metadata
    subset_patients
    ascat_outputs
    ascat_esimates
    analysis_type
    plot_dir
    gistic_refgene_file
    giab_regions
    cutoff
    chrom_arms
    
    main: 

    subset_patients 
    | splitCsv(sep:"\t", header:['tumor', 'normal']) 
    | map{ meta -> 
        [pair_id: meta.normal+ "_" + meta.tumor]
        }
    | set { subset_ids }

    ascat_outputs
    | flatMap{ n -> n}
    | map{ meta, segments, gistic -> [ subMap(meta.pair_id), meta, segments, gistic]}
    | groupTuple()
    | join(subset_ids)
    | transpose()
    | map { pair_id, meta, segments, gistic -> [meta, segments, gistic] }
    | set { ascat_subset_segments }

    ascat_estimates
    | flatMap{ n -> n}
    | map{ meta, estimate_file -> [ subMap(meta.pair_id), meta, estimate_file]}
    | groupTuple()
    | join(subset_ids)
    | transpose()
    | map { pair_id, meta, estimate_file -> [meta, estimate_file] }
    | set { ascat_subset_estimates }
    

    ascat_subset_estimates.collect()
    | map { file_list -> tuple([analysis_type: analysis_type], file_list) }
    | set { estimates_list }


    SUMMARISE_ASCAT_ESTIMATES(estimates_list)
    
    analysis_type = ascat_subset_estimates
    | map{ meta, file, seg -> [analysis_type: meta.analysis_type, plot_dir: meta.plot_dir]}
    
    ascat_subset_segments
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

    ascat_subset_segments
    | collectFile(
       storeDir: "${params.OUTDIR}/ASCAT/${params.release_version}"){
       meta, segments, gistic ->
        def filename = "${params.OUTDIR}/ASCAT/${params.release_version}/${meta.analysis_type}/${meta.analysis_type}_segments.txt"
        return [filename, gistic]}
    | merge(analysis_type)
    | map { file, meta -> [meta, file]}
    | set { gistic_ch }


    ascat_subset_segments
    | collectFile(
      storeDir: "${params.OUTDIR}/ASCAT/${params.release_version}"){
           meta, segments, gistic ->
        def filename = "${params.OUTDIR}/ASCAT/${params.release_version}/${meta.analysis_type}/samples2sex.txt"
        [filename, "${meta["tumor"]}\t${meta["sexchr"]}\n"]
    }
    | set { sex2chr_ch }
  

    CREATE_FREQUENCY_PLOTS(ascat_subset_segments,
                           SUMMARISE_ASCAT_ESTIMATES.out.purity,
                           sex2chr_ch, 
                           cohort_prefix)

    GISTIC2_ANALYSIS(gistic_ch,
                    CREATE_FREQUENCY_PLOTS.out.processed_segments, 
                    gistic_refgene_file, 
                    giab_regions,
                    chrom_arms,
                    cutoff,
                    cohort_prefix)
    


}