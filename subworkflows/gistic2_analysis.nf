include { RUN_GISTIC2; FILTER_GISTIC2_CALLS} from "../modules/gistic2.nf"
workflow GISTIC2_ANALYSIS {
    take:

    ascat_segments 
    gistic_refgene
    difficult_regions_file
    cohort_prefix

    main:

    RUN_GISTIC2(ascat_segments, gistic_refgene)
    FILTER_GISTIC2_CALLS(RUN_GISTIC2.out.segment_file, 
                        RUN_GISTIC2.out.lesions,
                        difficult_regions_file,
                        cohort_prefix)

}