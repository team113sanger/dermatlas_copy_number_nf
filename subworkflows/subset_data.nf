workflow SUBSET_DATASET {
    take:
    cohort_metadata
    filtered_ascat_outputs
    ascat_esimates
    analysis_type
    plot_dir
    
    main: 
    cohort_metadata
    | map { meta, nf, ni, tf, ti -> meta }
    | join(filtered_ascat_outputs)
    | map{ meta, ascat_segments, gistic_segments -> 
        tuple(meta + [analysis_type: analysis_type, plot_dir: plot_dir], 
              ascat_segments, gistic_segments) }
    | set { subset_files }

    estimate_file = cohort_metadata
    | map { meta, nf, ni, tf, ti -> [meta]}
    | join(ascat_esimates)
    | map{ meta, file -> file} 
    
    estimate_file.collect()
    | map { file_list -> tuple([analysis_type: analysis_type], file_list) }
    | set { estimates_list }

    emit:
    subset_files
    estimates_list


}