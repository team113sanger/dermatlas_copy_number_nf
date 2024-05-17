include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS } from '../modules/ascat.nf'

workflow ASCAT_ANALYSIS {
    take: 
    metadata
    sex2chr_ch
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

    estimates_list = RUN_ASCAT_EXOMES.out.estimates.collect{meta, file -> file}
    
    SUMMARISE_ASCAT_ESTIMATES(estimates_list)
    SUMMARISE_ASCAT_ESTIMATES.out.low_quality.splitCsv(sep:"\t", header:['pair_id'])
    | flatten()
    | set { pair_qualities }
    pair_qualities.view()


    RUN_ASCAT_EXOMES.out.segments
    | map{ meta, it -> it}
    | collectFile(name: 'one_patient_per_tumor.txt', 
                 keepHeader: true, 
                 skip: 1,
                 storeDir: output_dir)
    | set {segments_file}

    CREATE_FREQUENCY_PLOTS(segments_file, 
                           SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats,
                            sex2chr_ch)

    estimates = RUN_ASCAT_EXOMES.out.estimates    
    // plots = CREATE_FREQUENCY_PLOTS.out
emit: 
    segments_file
    estimates
    // plots
}