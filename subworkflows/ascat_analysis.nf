include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../modules/ascat.nf'

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

    EXTRACT_GOODNESS_OF_FIT(RUN_ASCAT_EXOMES.out.estimates)
    | set { quality_ch }

    RUN_ASCAT_EXOMES.out.estimates.collect{meta, file -> file}
    | set { estimates_list }
    
    SUMMARISE_ASCAT_ESTIMATES(estimates_list)
    
    RUN_ASCAT_EXOMES.out.segments
    | join(quality_ch)
    | filter{ meta, file, gof -> gof.toDouble() > 95}
    | map { meta, file, gof -> file }
    | collectFile(name: 'one_patient_per_tumor.txt', 
                 keepHeader: true, 
                 skip: 1,
                 storeDir: output_dir)
    | set { segment_summary }
    segment_summary.view()

    CREATE_FREQUENCY_PLOTS(segment_summary,
                           SUMMARISE_ASCAT_ESTIMATES.out.purity,
                           SUMMARISE_ASCAT_ESTIMATES.out.sex_stats, 
                           cohort_prefix)

    emit: 
    segment_summary
    RUN_ASCAT_EXOMES.out.estimates
}