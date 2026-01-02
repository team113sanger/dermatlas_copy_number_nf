include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../../modules/ascat.nf'

workflow ASCAT_ANALYSIS {
    take:
    metadata
    genome
    baits
    per_chrom_dir
    gc_file
    rt_file
    gof_threshold

    main:
    
    RUN_ASCAT_EXOMES(metadata,
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
    | combine(gof_threshold)
    | filter { _meta, _segement, _gistic, gof, threshold -> gof.toDouble() > threshold}
    | map { meta, segement, gistic, _gof, _threshold -> [meta, segement, gistic ] }
    | collect(flat: false)
    | set { filtered_outs }

    RUN_ASCAT_EXOMES.out.estimates
    | collect(flat: false)
    | set { estimates }
    
    emit: 
    filtered_outs
    estimates

}

