include { RUN_GISTIC; FILTER_GISTIC_CALLS} from "../modules/gistic.nf"
workflow GISTIC_ANALYSIS {
    take:

    ascat_segments 
    gistic_refgene
    difficult_regions_file
    cohort_prefix

    main:

    RUN_GISTIC(ascat_segments, gistic_refgene)
    FILTER_GISTIC_CALLS(RUN_GISTIC.out.segment_file, 
                        RUN_GISTIC.out.lesions,
                        difficult_regions_file,
                        cohort_prefix)

}