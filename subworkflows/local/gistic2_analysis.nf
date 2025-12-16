include { RUN_GISTIC2; FILTER_GISTIC2_CALLS; FILTER_BROAD_GISTIC2_CALLS } from "../../modules/gistic2.nf"
workflow GISTIC2_ANALYSIS {
    take:
    gistic_inputs
    ascat_segments
    gistic_refgene
    difficult_regions_file
    chrom_arms
    broad_cutoff
    focal_cutoff
    cohort_prefix

    main:
    RUN_GISTIC2(gistic_inputs,
                gistic_refgene)

    // Join ascat_segments with lesions for FILTER_GISTIC2_CALLS
    ascat_segments
    | join(RUN_GISTIC2.out.lesions)
    | set { segments_with_lesions }

    FILTER_GISTIC2_CALLS(
                        segments_with_lesions,
                        difficult_regions_file,
                        focal_cutoff,
                        cohort_prefix)

    // Join ascat_segments with broad and arms for FILTER_BROAD_GISTIC2_CALLS
    ascat_segments
    | join(RUN_GISTIC2.out.broad)
    | join(RUN_GISTIC2.out.arms)
    | set { segments_with_broad }

    FILTER_BROAD_GISTIC2_CALLS(
                       segments_with_broad,
                       chrom_arms,
                       broad_cutoff,
                       cohort_prefix)
    emit: 
    gistic_tabs    = RUN_GISTIC2.out.tables
    sample_summary = FILTER_GISTIC2_CALLS.out.ss
    cohort_summary = FILTER_GISTIC2_CALLS.out.cs

}