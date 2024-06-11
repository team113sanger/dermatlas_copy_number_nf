include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../modules/ascat.nf'

workflow ASCAT_ANALYSIS {
    take: 
    metadata
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


    RUN_ASCAT_EXOMES.out.segments
    | join(RUN_ASCAT_EXOMES.out.gistic_inputs)
    | join(quality_ch)
    | filter { meta, segement, gistic, gof -> gof.toDouble() > 95}
    | map { meta, segement, gistic, gof -> [meta, segement, gistic ] }
    | set { filtered_outs }

    RUN_ASCAT_EXOMES.out.estimates
    | set { estimates }
    
    emit: 
    filtered_outs
    estimates

}

