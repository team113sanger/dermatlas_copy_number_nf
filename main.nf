#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { RUN_ASCAT_EXOMES } from './modules/ascat.nf'
include { DERMATLAS_METADATA } from './subworkflows/ingest_dermatlas.nf'



workflow {
bamfiles = Channel.fromPath("tests/testdata/*.bam")
pair_ids   = Channel.fromPath("tests/testdata/pair_ids.tsv")
patient_md = Channel.fromPath("tests/testdata/metadata_tab")
DERMATLAS_METADATA(bamfiles, pair_ids, patient_md)


RUN_ASCAT_EXOMES(DERMATLAS_METADATA.out, 
                 params.OUTDIR, 
                 params.PROJECTDIR)
    
}
