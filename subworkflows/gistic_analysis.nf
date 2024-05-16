include {RUN_GISTIC; FILTER_GISTIC_CALLS} from "../modules/gistic.nf"
workflow GISTIC_ANALYSIS {
    take: 
    ascat_segments 
    project_dir
    output_dir
    refgenefile

    main:
    RUN_GISTIC(ascat_segments)
    FILTER_GISTIC_CALLS()

    emit:
}