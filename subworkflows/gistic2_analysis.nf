include { RUN_GISTIC2; FILTER_GISTIC2_CALLS} from "../modules/gistic2.nf"
workflow GISTIC2_ANALYSIS {
    take:
    gistic_inputs 
    gistic_refgene
    difficult_regions_file
    cohort_prefix

    main:
    RUN_GISTIC2(gistic_inputs, gistic_refgene)
    FILTER_GISTIC2_CALLS(RUN_GISTIC2.out.segment_file, 
                        RUN_GISTIC2.out.lesions,
                        difficult_regions_file,
                        cohort_prefix)
    emit: 
    gistic_tabs    = RUN_GISTIC2.out.tables
    sample_summary = FILTER_GISTIC2_CALLS.out.ss
    cohort_summary = FILTER_GISTIC2_CALLS.out.cs

}