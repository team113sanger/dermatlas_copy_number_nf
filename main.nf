#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { RUN_ASCAT_EXOMES } from './modules/ascat.nf'
include { INGEST_DERMATLAS } from './subworkflows/ingest_dermatlas.nf'



workflow {
bamfiles = Channel.fromPath("tests/testdata/*.bam")
pair_ids   = Channel.fromPath("tests/testdata/pair_ids.tsv")
patient_md = Channel.fromPath("tests/testdata/metadata_tab")
INGEST_DERMATLAS(bamfiles, pair_ids, patient_md)


RUN_ASCAT_EXOMES(INGEST_DERMATLAS.out, params.OUTDIR, params.PROJECTDIR)
    
}

// params.sample_list="${params.projdir}/*_tumour_normal_submitted_caveman.txt"
// params.metadata_file="${params.projdir}/*_METADATA_*.t*"