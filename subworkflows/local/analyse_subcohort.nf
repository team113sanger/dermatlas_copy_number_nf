include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../../modules/ascat.nf'
include { GISTIC2_ANALYSIS } from './gistic2_analysis.nf'

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
    ensembl_transcript
    cancer_gene_list
    oncokb_file
    log2thresholds

    main:

    // Build a set of (pair_id, cohort_name, plot_dir) for filtering
    cohort_sample_sets
    | flatMap { cohort_name, sample_list, plot_dir ->
        sample_list.splitCsv(sep: "\t", header: ['tumor', 'normal'])
            .collect { row ->
                tuple(row.normal + "_" + row.tumor, cohort_name, plot_dir)
            }
    }
    | set { sample_to_cohort }

    // Combine ASCAT outputs with cohort membership, filter matches
    ascat_outputs
    | flatMap { n -> n }
    | combine(sample_to_cohort)
    | filter { meta, segments, gistic, pair_id, cohort_name, plot_dir ->
        meta.pair_id == pair_id
    }
    | map { meta, segments, gistic, _pair_id, cohort_name, plot_dir ->
        [meta + [analysis_type: cohort_name, plot_dir: plot_dir], segments, gistic]
    }
    | set { ascat_subset_segments }

    // Combine ASCAT estimates with cohort membership, filter matches
    ascat_estimates
    | flatMap { n -> n }
    | combine(sample_to_cohort)
    | filter { meta, estimate_file, pair_id, cohort_name, plot_dir ->
        meta.pair_id == pair_id
    }
    | map { meta, estimate_file, _pair_id, cohort_name, plot_dir ->
        tuple([analysis_type: cohort_name, plot_dir: plot_dir], estimate_file)
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
                    cohort_prefix,
                    ensembl_transcript,
                    cancer_gene_list,
                    oncokb_file,
                    log2thresholds)



}