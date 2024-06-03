include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../modules/ascat.nf'

workflow ASCAT_ANALYSIS {
    take: 
    metadata
    sex2chr_ch
    output_dir
    genome
    baits
    per_chrom_dir
    gc_file
    rt_file
    cohort_prefix

    main:
    
    RUN_ASCAT_EXOMES(metadata,
                     output_dir,
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
    | collectFile(name: 'combined_segment_file.txt', 
                 keepHeader: true, 
                 skip: 1)
    | set { segment_summary }


    RUN_ASCAT_EXOMES.out.gistic_inputs
    | join(quality_ch)
    | filter{ meta, file, gof -> gof.toDouble() > 95}
    | map { meta, file, gof -> file }
    | collectFile(name: 'one_tumor_per_patient_segs.tsv', 
                 storeDir: output_dir)
    | set { gistic_inputs }

    CREATE_FREQUENCY_PLOTS(segment_summary,
                           SUMMARISE_ASCAT_ESTIMATES.out.purity,
                           sex2chr_ch, 
                           cohort_prefix)

    emit: 
    segments      =   CREATE_FREQUENCY_PLOTS.out.processed_segments
    estimates     =   RUN_ASCAT_EXOMES.out.estimates
    gistic_inputs =   gistic_inputs
    purity        =   SUMMARISE_ASCAT_ESTIMATES.out.purity
    summary_stats =   SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats
    freq_tab      =   CREATE_FREQUENCY_PLOTS.out.table
}