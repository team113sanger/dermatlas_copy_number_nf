include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../modules/ascat.nf'
include { GISTIC2_ANALYSIS } from '../subworkflows/gistic2_analysis.nf'

workflow ANALYSE_SUBCOHORT {
    take:
    cohort_sample_sets    // channel of (cohort_name, sample_list_file, plot_dir) tuples
    ascat_outputs
    ascat_estimates
    cohort_prefix
    gistic_refgene_file
    giab_regions
    broad_cutoff
    focal_cutoff
    chrom_arms

    main:

    // Parse sample lists and add cohort metadata
    cohort_sample_sets
    | flatMap { cohort_name, sample_list, plot_dir ->
        sample_list.splitCsv(sep: "\t", header: ['tumor', 'normal'])
            .collect { row ->
                tuple(
                    [pair_id: row.normal + "_" + row.tumor],
                    cohort_name,
                    plot_dir
                )
            }
    }
    | set { subset_ids_with_cohort }

    // Extract just the pair_ids for joining
    subset_ids_with_cohort
    | map { pair_id_map, _cohort, _plot_dir -> pair_id_map }
    | set { subset_ids }

    // Create a lookup channel for cohort info by pair_id
    subset_ids_with_cohort
    | map { pair_id_map, cohort_name, plot_dir ->
        tuple(pair_id_map, [analysis_type: cohort_name, plot_dir: plot_dir])
    }
    | set { cohort_lookup }

    ascat_outputs
    | flatMap{ n -> n}
    | map{ meta, segments, gistic -> [ meta.subMap('pair_id'), meta, segments, gistic]}
    | groupTuple()
    | join(subset_ids)
    | transpose()
    | join(cohort_lookup)
    | map { _pair_id, meta, segments, gistic, cohort_info ->
        [meta + cohort_info, segments, gistic]
    }
    | set { ascat_subset_segments }

    ascat_estimates
    | flatMap{ n -> n}
    | map{ meta, estimate_file -> [ meta.subMap('pair_id'), meta, estimate_file]}
    | groupTuple()
    | join(subset_ids)
    | transpose()
    | join(cohort_lookup)
    | map { _pair_id, _meta, estimate_file, cohort_info ->
        tuple(cohort_info, estimate_file)
    }
    | set { ascat_subset_estimates }

    // Group estimates by cohort for SUMMARISE_ASCAT_ESTIMATES
    ascat_subset_estimates
    | groupTuple()
    | set { estimates_list }

    SUMMARISE_ASCAT_ESTIMATES(estimates_list)

    // Create a lookup channel for analysis_type -> plot_dir mapping
    ascat_subset_segments
    | map { meta, _segments, _gistic -> tuple(meta.analysis_type, meta.plot_dir) }
    | unique()
    | set { plot_dir_lookup }

    ascat_subset_segments.collectFile(keepHeader: true,
                 storeDir: "${params.outdir}/ASCAT/${params.release_version}",
                 skip: 1){
                 meta, segments, _gistic ->
                 new File("${params.outdir}/ASCAT/${params.release_version}/${meta.analysis_type}").mkdirs()
                 def filename = "${meta.analysis_type}/combined_segment_file.txt"
                 return [filename, segments]
                 }
    | map{ combined_file ->
        def analysis_type = combined_file.parent.name
        tuple(analysis_type, combined_file)
    }
    | join(plot_dir_lookup)
    | map { analysis_type, combined_file, plot_dir ->
        tuple([analysis_type: analysis_type, plot_dir: plot_dir], combined_file)
    }
    | set { segment_summary }

    ascat_subset_segments.collectFile(
       storeDir: "${params.outdir}/ASCAT/${params.release_version}"){
       meta, _segments, gistic ->
        def filename = "${meta.analysis_type}/${meta.analysis_type}_segments.txt"
        return [filename, gistic]}
    | map{ gistic_file ->
        def analysis_type = gistic_file.parent.name
        tuple(analysis_type, gistic_file)
    }
    | join(plot_dir_lookup)
    | map { analysis_type, gistic_file, plot_dir ->
        tuple([analysis_type: analysis_type, plot_dir: plot_dir], gistic_file)
    }
    | set { gistic_ch }


    ascat_subset_segments.collectFile(
      storeDir: "${params.outdir}/ASCAT/${params.release_version}"){
           meta, _segments, _gistic ->
        def filename = "${meta.analysis_type}/samples2sex.txt"
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
                    broad_cutoff,
                    focal_cutoff,
                    cohort_prefix)



}