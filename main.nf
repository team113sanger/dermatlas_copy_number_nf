#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS } from './modules/ascat.nf'
include { RUN_GISTIC } from './modules/gistic.nf'

include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'



workflow {
bamfiles   = Channel.fromPath(params.bamfiles)
pair_ids   = Channel.fromPath(params.pair_ids)
patient_md = Channel.fromPath(params.metadata)
DERMATLAS_METADATA(bamfiles, pair_ids, patient_md)


RUN_ASCAT_EXOMES(DERMATLAS_METADATA.out, 
                 params.OUTDIR, 
                 params.PROJECTDIR)


segments_list = RUN_ASCAT_EXOMES.out.segments.collect{meta, file -> file}
// DERMATLAS_METADATA.out
// .collectFile{
//     meta, tumor_bam, normal_bam -> 
//     [meta[0].subMap("pair_id"), meta[1].subMap("sexchr")],
//     name: 'samples2chr.tsv' }
SUMMARISE_ASCAT_ESTIMATES(
    RUN_ASCAT_EXOMES.out.estimates.collect{meta, file -> file}
    )

CREATE_FREQUENCY_PLOTS(
    segments_list,
    SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats
    )

// GISTIC(segments_list)

// RUN_ASCAT_EXOMES.out.segments.map{groupkey, meta, normal,tumor -> groupKey.target}.view()


}
