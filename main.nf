#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'
include { ASCAT_ANALYSIS } from './subworkflows/ascat_analysis.nf'
include { GISTIC2_ANALYSIS } from './subworkflows/gistic2_analysis.nf'

workflow {

    // Cohort files 
    bamfiles    = Channel.fromPath(params.bam_files, checkIfExists: true)
    pair_ids    = Channel.fromPath(params.tumor_normal_pairs, checkIfExists: true)
    patient_md  = Channel.fromPath(params.metadata_manifest, checkIfExists: true)

    // Reference files
    reference_genome = file(params.reference_genome, checkIfExists: true)
    bait_set = file(params.bait_set, checkIfExists: true)
    per_chrom_files = file(params.resource_files, checkIfExists: true)
    gc_file = file(params.gc_file, checkIfExists: true)
    rt_file = file(params.rt_file, checkIfExists: true)
    giab_regions = file(params.difficult_regions_file, checkIfExists: true)


    DERMATLAS_METADATA(bamfiles, 
                       pair_ids, 
                       patient_md, 
                       params.OUTDIR)

    ASCAT_ANALYSIS(DERMATLAS_METADATA.out.combined_metadata,
                   params.OUTDIR,  
                   reference_genome,
                   bait_set,
                   per_chrom_files,
                   gc_file,
                   rt_file,
                   params.cohort_prefix)
    
    GISTIC2_ANALYSIS(ASCAT_ANALYSIS.out.segment_summary, 
                    params.gistic_refgene_file, 
                    giab_regions,
                    params.cohort_prefix)


}
