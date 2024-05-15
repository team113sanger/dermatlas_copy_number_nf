#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { RUN_GISTIC } from './modules/gistic.nf'
include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'
include { ASCAT_ANALYSIS } from './subworkflows/ascat_analysis.nf'

workflow {
    bamfiles   = Channel.fromPath(params.bamfiles)
    pair_ids   = Channel.fromPath(params.pair_ids)
    patient_md = Channel.fromPath(params.metadata)

    DERMATLAS_METADATA(bamfiles, pair_ids, patient_md)


    ASCAT_ANALYSIS(DERMATLAS_METADATA.out, 
                    params.OUTDIR, 
                    params.PROJECTDIR)
    // ASCAT_ANALYSIS.out.estimates.view()
    // ASCAT_ANALYSIS.out.segments.view()
    // GISTIC(segments_list)
    // SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats[4]
    //  .splitCsv( header: true )
    // RUN_ASCAT_EXOMES.out.segments.map{groupkey, file -> groupkey.target}.view()


}
