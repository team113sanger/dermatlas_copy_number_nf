#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS } from './modules/ascat.nf'
include { DERMATLAS_METADATA } from './subworkflows/ingest_dermatlas.nf'



workflow {
bamfiles = Channel.fromPath(params.bamfiles)
pair_ids   = Channel.fromPath(params.pair_ids)
patient_md = Channel.fromPath(params.metadata)
DERMATLAS_METADATA(bamfiles, pair_ids, patient_md)


RUN_ASCAT_EXOMES(DERMATLAS_METADATA.out, 
                 params.OUTDIR, 
                 params.PROJECTDIR)
stats_ch = RUN_ASCAT_EXOMES.out.estimates.collect().view()
SUMMARISE_ASCAT_ESTIMATES(stats_ch)
    
}
