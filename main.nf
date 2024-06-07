#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'
include { ASCAT_ANALYSIS } from './subworkflows/ascat_analysis.nf'
include { GISTIC2_ANALYSIS } from './subworkflows/gistic2_analysis.nf'
include { REFORMAT_TSV } from './modules/publish.nf'

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
    chrom_arms = file(params.chrom_arms, checkIfExists: true)

    // Combine and pivot the metadata so that TN pair bams and meta are a single
    // data structure
    DERMATLAS_METADATA(bamfiles, 
                       pair_ids, 
                       patient_md)
    
    // Run Ascat, summarise estimates and plot 
    ASCAT_ANALYSIS(DERMATLAS_METADATA.out.combined_metadata,
                   DERMATLAS_METADATA.out.sex2chr_ch,
                   params.OUTDIR,  
                   reference_genome,
                   bait_set,
                   per_chrom_files,
                   gc_file,
                   rt_file,
                   params.cohort_prefix)
    
    // Given Ascat segments, run Gistic2 and filter regions 
    GISTIC2_ANALYSIS(ASCAT_ANALYSIS.out.gistic_inputs,
                    ASCAT_ANALYSIS.out.segments, 
                    params.gistic_refgene_file, 
                    giab_regions,
                    params.cohort_prefix,
                    params.broad_cutoff
                    chrom_arms)
    
    // Convert all tab files to tsv. TODO 
    // ASCAT_ANALYSIS.out.freq_tab
    // | concat(ASCAT_ANALYSIS.out.purity)
    // | concat(ASCAT_ANALYSIS.out.summary_stats) 
    // | concat(GISTIC2_ANALYSIS.out.gistic_tabs)
    // | concat(GISTIC2_ANALYSIS.out.sample_summary)
    // | concat(GISTIC2_ANALYSIS.out.cohort_summary)
    // | set { tabular_ch }
    
    // REFORMAT_TSV( tabular_ch )


}
