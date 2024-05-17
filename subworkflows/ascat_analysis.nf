include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS } from '../modules/ascat.nf'

workflow ASCAT_ANALYSIS {
    take: 
    metadata
    output_dir
    project_dir
    genome
    baits
    per_chrom_dir
    gc_file
    rt_file

    main:
    RUN_ASCAT_EXOMES(metadata,
                    output_dir,
                    project_dir,
                    genome,
                    baits,
                    per_chrom_dir,
                    gc_file,
                    rt_file)

    segments_list  = RUN_ASCAT_EXOMES.out.segments
    // .filter{meta, file -> meta[0]['pair_id'] in }
    // .collect{meta, file -> file}
    estimates_list = RUN_ASCAT_EXOMES.out.estimates.collect{meta, file -> file}
   

    
    SUMMARISE_ASCAT_ESTIMATES(estimates_list)
    SUMMARISE_ASCAT_ESTIMATES.out.low_quality.splitCsv(sep:"\t", header:['pair_id'])
    | flatten()
    | set { pair_qualities }
    pair_qualities.view()

    // RUN_ASCAT_EXOMES.out.plots.map{
    // meta, plots -> 
    // [meta[0].subMap("pair_id"), meta[1].subMap("sexchr")]
    // }
    // | collectFile(name: 'samples2sex.tsv') 
    // | set {sex_chr_ch}
    // sex_chr_ch.view()

    // all_ascat = RUN_ASCAT_EXOMES.out.segments
    //             | map{ it -> }
    // pair_qualities
    // .join()


    // CREATE_FREQUENCY_PLOTS(segments_list, 
    //                        SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats,
    //                        sex_chr_ch)
    segments = RUN_ASCAT_EXOMES.out.segments
    estimates = RUN_ASCAT_EXOMES.out.estimates    
    // plots = CREATE_FREQUENCY_PLOTS.out
emit: 
    segments
    estimates
    // plots
}