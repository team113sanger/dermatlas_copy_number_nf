include { RUN_GISTIC; FILTER_GISTIC_CALLS} from "../modules/gistic.nf"
 workflow GISTIC_ANALYSIS {
     take: 
     ascat_segments 
     gistic_refgene

    main:
    RUN_GISTIC(ascat_segments, gistic_refgene)
    FILTER_GISTIC_CALLS(RUN_GISTIC.out.lesions, RUN_GISTIC.out.segment_file)

}