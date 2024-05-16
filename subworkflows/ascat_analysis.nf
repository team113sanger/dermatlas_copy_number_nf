include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS } from '../modules/ascat.nf'

workflow ASCAT_ANALYSIS {
    take: 
    metadata
    output_dir
    project_dir
    ref_files
    
    main:
    RUN_ASCAT_EXOMES(metadata,
                    output_dir,
                    project_dir,
                    ref_files)

    // segments_list  = RUN_ASCAT_EXOMES.out.segments
    // .filter{meta, file -> meta[0]['pair_id'] in }
    // .collect{meta, file -> file}
    // estimates_list = RUN_ASCAT_EXOMES.out.estimates.collect{meta, file -> file}
    // metadata \
    // | collectFile(name: 'samples2chr.tsv', storeDir: $"{params.OUTDIR}"){
    //     meta, tumor_bam, normal_bam -> 
    //     [meta[0].subMap("pair_id"), meta[1].subMap("sexchr")],
    //    }
    
    // SUMMARISE_ASCAT_ESTIMATES(estimates_list)
    // SUMMARISE_ASCAT_ESTIMATES.out.ascat.low_quality
    // .splitCsv(sep:"\t",header:['pair_id'])
    // .flatten()
    // .set { pair_qualities }
    // pair_qualities.view()

    // all_ascat = RUN_ASCAT_EXOMES.out.segments
    //             | map{ it -> }
    // pair_qualities
    // .join()


    // CREATE_FREQUENCY_PLOTS(
    //     segments_list,
    //     SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats
    //     )
    // segments = RUN_ASCAT_EXOMES.out.segments
    // estimates = RUN_ASCAT_EXOMES.out.estimates    
    // plots = CREATE_FREQUENCY_PLOTS.out
// emit: 
    // segments
    // estimates
    // plots
}