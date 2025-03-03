include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../modules/ascat.nf'
include { GISTIC2_ANALYSIS } from '../subworkflows/gistic2_analysis.nf'

workflow ANALYSE_SUBCOHORT {
    take:
    cohort_metadata
    subset_patients
    ascat_outputs
    ascat_estimates
    analysis_type
    plot_dir
    output_dir
    cohort_prefix
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
    | map{ meta, segments, gistic -> [ meta.subMap('pair_id'), meta, segments, gistic]}
    | groupTuple()
    | join(subset_ids)
    | transpose()
    | map { pair_id, meta, segments, gistic -> [meta + [analysis_type: analysis_type, plot_dir: plot_dir], segments, gistic] }
    | set { ascat_subset_segments }

    ascat_estimates
    | flatMap{ n -> n}
    | map{ meta, estimate_file -> [ meta.subMap('pair_id'), meta, estimate_file]}
    | groupTuple()
    | join(subset_ids)
    | transpose()
    | map { pair_id, meta, estimate_file -> estimate_file }
    | set { ascat_subset_estimates }


    ascat_subset_estimates.collect()
    | map{ file_list -> tuple([analysis_type: analysis_type], file_list)}
    | set { estimates_list }

    SUMMARISE_ASCAT_ESTIMATES(estimates_list)
    
  
    ascat_subset_segments.collectFile(keepHeader: true,
                 storeDir: "${params.outdir}/ASCAT/${params.release_version}", 
                 skip: 1){
                 meta, segments, gistic -> 
                 new File("${params.outdir}/ASCAT/${params.release_version}/${meta.analysis_type}").mkdirs()
                 def filename = "${params.outdir}/ASCAT/${params.release_version}/${meta.analysis_type}/combined_segment_file.txt"
                 return [filename, segments]
                 }
    | map{ file_list -> tuple([analysis_type: analysis_type, plot_dir:plot_dir], file_list)}
    | set { segment_summary }

    ascat_subset_segments.collectFile(
       storeDir: "${params.outdir}/ASCAT/${params.release_version}"){
       meta, segments, gistic ->
        def filename = "${params.outdir}/ASCAT/${params.release_version}/${meta.analysis_type}/${meta.analysis_type}_segments.txt"
        return [filename, gistic]}
    | map{ file_list -> tuple([analysis_type: analysis_type, plot_dir:plot_dir], file_list)}
    | set { gistic_ch }


    ascat_subset_segments.collectFile(
      storeDir: "${params.outdir}/ASCAT/${params.release_version}"){
           meta, segments, gistic ->
        def filename = "${params.outdir}/ASCAT/${params.release_version}/${meta.analysis_type}/samples2sex.txt"
        [filename, "${meta["tumor"]}\t${meta["Sex"]}\n"]
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
                    chrom_arms,
                    cutoff,
                    cohort_prefix)
    


}