include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS } from '../modules/ascat.nf'

workflow ASCAT_ANALYSIS {
    take: 
    metadata
    output_dir
    project_dir

    main:
    RUN_ASCAT_EXOMES(metadata,
                    output_dir,
                    project_dir)

    segments_list = RUN_ASCAT_EXOMES.out.segments.collect{meta, file -> file}
    // DERMATLAS_METADATA.out
    // .collectFile{
    //     meta, tumor_bam, normal_bam -> 
    //     [meta[0].subMap("pair_id"), meta[1].subMap("sexchr")],
    //     name: 'samples2chr.tsv' }
    SUMMARISE_ASCAT_ESTIMATES( RUN_ASCAT_EXOMES.out.estimates.collect{meta, file -> file})

    CREATE_FREQUENCY_PLOTS(
        segments_list,
        SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats
        )
    segments = RUN_ASCAT_EXOMES.out.segments
    estimates = RUN_ASCAT_EXOMES.out.estimates    
    plots = CREATE_FREQUENCY_PLOTS.out
emit: 
    segments
    estimates
    plots
}