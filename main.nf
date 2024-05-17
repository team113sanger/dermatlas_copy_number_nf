#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'
include { ASCAT_ANALYSIS } from './subworkflows/ascat_analysis.nf'
include { GISTIC_ANALYSIS } from './subworkflows/gistic_analysis.nf'

workflow {
    bamfiles   = Channel.fromPath(params.bam_files)
    index_files = Channel.fromPath(params.index_files)
    pair_ids   = Channel.fromPath(params.tumor_normal_pairs)
    patient_md = Channel.fromPath(params.metadata_manifest)
    reference_genome = file(params.reference_genome)
    bait_set = file(params.bait_set)
    per_chrom_files = file(params.resource_files)
    gc_file = file(params.gc_file)
    rt_file = file(params.rt_file)


    DERMATLAS_METADATA(bamfiles, 
                       index_files, 
                       pair_ids, 
                       patient_md, 
                       params.OUTDIR)

    ASCAT_ANALYSIS(DERMATLAS_METADATA.out.combined_metadata,
                   DERMATLAS_METADATA.out.sex2chr_ch,
                    params.OUTDIR, 
                    params.PROJECTDIR, 
                    reference_genome,
                    bait_set,
                    per_chrom_files,
                    gc_file,
                    rt_file)
    
    // GISTIC_ANALYSIS(ASCAT_ANALYSIS.out.segments, 
    //                 params.gistic_refgene_file)


}
