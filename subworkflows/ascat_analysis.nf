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
    cohort_prefix

    main:
    
    RUN_ASCAT_EXOMES(metadata,
                    output_dir,
                    project_dir,
                    genome,
                    baits,
                    per_chrom_dir,
                    gc_file,
                    rt_file)

    RUN_ASCAT_EXOMES.out.estimates.collect{meta, file -> file}
    | set { estimates_list }
    
    SUMMARISE_ASCAT_ESTIMATES(estimates_list)
    SUMMARISE_ASCAT_ESTIMATES.out.low_quality
    | splitCsv(sep:"\t", header:['pair_id'])
    | flatten()
    | set { pair_qualities }



    RUN_ASCAT_EXOMES.out.segments
    // | filter {meta, it }
    | map{ meta, it -> it}
    | collectFile(name: 'one_patient_per_tumor.txt', 
                 keepHeader: true, 
                 skip: 1,
                 storeDir: output_dir)
    | set {segment_summary}
    
    segment_files =  RUN_ASCAT_EXOMES.out.segments.collect()

    CREATE_FREQUENCY_PLOTS(segment_summary,
                           SUMMARISE_ASCAT_ESTIMATES.out.purity,
                           SUMMARISE_ASCAT_ESTIMATES.out.sex_stats, 
                           cohort_prefix)

    emit: 
    segment_summary
    RUN_ASCAT_EXOMES.out.estimates
}