include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../modules/ascat.nf'

workflow ANALYSE_ASCAT_COHORT {
    take: 
    ascat_subgroup
    gistic_inputs
    quality_ch
    analysis_type
    sex2chr_ch
    
    main:
    
    ascat_subgroup.collect{meta, file -> file}
    | set { estimates_list }
    
    SUMMARISE_ASCAT_ESTIMATES(estimates_list)
    
    ascat_subgroup.map { meta, file, gof -> file }
    | collectFile(name: 'combined_segment_file.txt', 
                 keepHeader: true, 
                 skip: 1)
    | set { segment_summary }

    gistic_inputs.collectFile(name: 'one_tumor_per_patient_segs.tsv', 
                 storeDir: output_dir)
    | set { gistic_ch }

    CREATE_FREQUENCY_PLOTS(segment_summary,
                           SUMMARISE_ASCAT_ESTIMATES.out.purity,
                           sex2chr_ch, 
                           cohort_prefix)

    emit: 
    segments      =   CREATE_FREQUENCY_PLOTS.out.processed_segments
    gistic_inputs =   gistic_ch
    purity        =   SUMMARISE_ASCAT_ESTIMATES.out.purity
    summary_stats =   SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats
    freq_tab      =   CREATE_FREQUENCY_PLOTS.out.table
}