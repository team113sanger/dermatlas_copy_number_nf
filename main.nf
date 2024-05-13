#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS } from './modules/ascat.nf'
include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'



workflow {
bamfiles = Channel.fromPath(params.bamfiles)
pair_ids   = Channel.fromPath(params.pair_ids)
patient_md = Channel.fromPath(params.metadata)
DERMATLAS_METADATA(bamfiles, pair_ids, patient_md)


RUN_ASCAT_EXOMES(DERMATLAS_METADATA.out, 
                 params.OUTDIR, 
                 params.PROJECTDIR)

DERMATLAS_METADATA.out
.collectFile{
    meta, tumor_bam, normal_bam -> 
    [meta[0].subMap("pair_id"), meta[1].subMap("sexchr")],
    name: 'samples2chr.tsv' }
SUMMARISE_ASCAT_ESTIMATES(
    RUN_ASCAT_EXOMES.out.estimates
    )
CREATE_FREQUENCY_PLOTS(
    SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats
    )
    
}
