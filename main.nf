#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'
include { DERMATLAS_METADATA as ONE_PATIENT_PER_TUMOUR } from './subworkflows/process_metadata.nf'
include { DERMATLAS_METADATA as INDEPENDENT } from './subworkflows/process_metadata.nf'
include { ASCAT_ANALYSIS } from './subworkflows/ascat_analysis.nf'
include { ANALYSE_COHORT } from './subworkflows/subgroup_analysis.nf'
include { GISTIC2_ANALYSIS } from './subworkflows/gistic2_analysis.nf'
include { REFORMAT_TSV } from './modules/publish.nf'

workflow {

    // Cohort files 
    bamfiles    = Channel.fromPath(params.bam_files, checkIfExists: true)
    all_pairs    = Channel.fromPath(params.tumor_normal_pairs, checkIfExists: true)
    patient_md  = Channel.fromPath(params.metadata_manifest, checkIfExists: true)
    unique_pairs = Channel.fromPath(params.one_per_patient, checkIfExists: true)
    independent_tumors = Channel.fromPath(params.independent, checkIfExists: true)
    broad_cutoff = Channel.of("0.1")
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
                       all_pairs,
                       patient_md)

    ONE_PATIENT_PER_TUMOUR(bamfiles, 
                           unique_pairs,
                           patient_md)

    INDEPENDENT(bamfiles, 
                independent_tumors,
                patient_md)
    // Perform Ascat analysis on both the independent tumors and 
    // one-per-patient datasets.
    ASCAT_ANALYSIS(DERMATLAS_METADATA.out.combined_metadata,
                   params.OUTDIR,  
                   reference_genome,
                   bait_set,
                   per_chrom_files,
                   gc_file,
                   rt_file,
                   params.cohort_prefix)
    ASCAT_ANALYSIS.out.estimates.view()
    ONE_PATIENT_PER_TUMOUR.out.combined_metadata
    | map { meta, nf,ni, tf, ti -> meta}
    | join(ASCAT_ANALYSIS.out.filtered_outs) 
    | set { one_per_patient_cohort }

    INDEPENDENT.out.combined_metadata
    | map { meta, nf,ni, tf, ti -> meta}
    | join(ASCAT_ANALYSIS.out.filtered_outs)
    | set { independent_cohort }

    // ASCAT_ANALYSIS.out.filtered_outs.view()
    INDEPENDENT.out.combined_metadata 
    | map { meta, nf, ni, tf, ti -> meta}
    | join(ASCAT_ANALYSIS.out.estimates)
    // | view()
    | set { estimates_list }
    // estimates_list.collect{ meta, file -> file}.view()

    analysis_type = Channel.of("independent")
    
    ANALYSE_COHORT(independent_cohort,
                   estimates_list,
                   analysis_type,
                   params.OUTDIR,
                   params.cohort_prefix,
                   params.gistic_refgene_file,
                   giab_regions,
                   broad_cutoff,
                   chrom_arms)
    
    // // Given Ascat segments, run Gistic2 and filter regions 
    
    
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
