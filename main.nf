#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
// Repeated data ingestion for whole and subgroups of samples
include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'
include { DERMATLAS_METADATA as ONE_PATIENT_PER_TUMOUR } from './subworkflows/process_metadata.nf'
include { DERMATLAS_METADATA as INDEPENDENT } from './subworkflows/process_metadata.nf'

include { ASCAT_ANALYSIS } from './subworkflows/ascat_analysis.nf'
// Repeated cohort analysis forsubgroups of samples
include { ANALYSE_COHORT as ONE_PATIENT_PER_TUMOUR_COHORT } from './subworkflows/subgroup_analysis.nf'
include { ANALYSE_COHORT as INDEPENDENT_COHORT } from './subworkflows/subgroup_analysis.nf'

include { REFORMAT_TSV } from './modules/publish.nf'

workflow {

    // Cohort files 
    bamfiles           = Channel.fromPath(params.bam_files, checkIfExists: true)
    all_pairs          = Channel.fromPath(params.tumor_normal_pairs, checkIfExists: true)
    unique_pairs       = Channel.fromPath(params.one_per_patient, checkIfExists: true)
    independent_tumors = Channel.fromPath(params.independent, checkIfExists: true)
    patient_md         = Channel.fromPath(params.metadata_manifest, checkIfExists: true)
    
    // Reference files 
    reference_genome   = file(params.reference_genome, checkIfExists: true)
    bait_set           = file(params.bait_set, checkIfExists: true)
    per_chrom_files    = file(params.resource_files, checkIfExists: true)
    gc_file            = file(params.gc_file, checkIfExists: true)
    rt_file            = file(params.rt_file, checkIfExists: true)
    giab_regions       = file(params.difficult_regions_file, checkIfExists: true)
    chrom_arms         = file(params.chrom_arms_file, checkIfExists: true)
    broad_cutoff       = Channel.of(params.gistic_broad_peak_q_cutoff)

    // Combine and pivot the metadata so that T/N pair 
    // bams and metadata are a single channel
    DERMATLAS_METADATA(bamfiles, 
                       all_pairs,
                       patient_md)

    ONE_PATIENT_PER_TUMOUR(bamfiles, 
                           unique_pairs,
                           patient_md)

    INDEPENDENT(bamfiles, 
                independent_tumors,
                patient_md)

    // Perform ASCAT analysis on the entire dataset
    ASCAT_ANALYSIS(DERMATLAS_METADATA.out.combined_metadata,
                   params.OUTDIR,  
                   reference_genome,
                   bait_set,
                   per_chrom_files,
                   gc_file,
                   rt_file,
                   params.cohort_prefix)
    // Filter 
    ONE_PATIENT_PER_TUMOUR.out.combined_metadata
    | map { meta, nf, ni, tf, ti -> meta} 
    | join(ASCAT_ANALYSIS.out.filtered_outs)
    | set { one_per_patient_cohort }

    INDEPENDENT.out.combined_metadata
    | map { meta, nf,ni, tf, ti -> meta}
    | join(ASCAT_ANALYSIS.out.filtered_outs)
    | set { independent_cohort }

    ONE_PATIENT_PER_TUMOUR.out.combined_metadata
    | map { meta, nf, ni, tf, ti -> [meta]}
    | join(ASCAT_ANALYSIS.out.estimates)
    | map{ meta, file -> file} 
    | set { estimate_file }
    
    estimate_file.collect()
    | set { estimates_list }

    ONE_PATIENT_PER_TUMOUR_COHORT(one_per_patient_cohort,
                   estimates_list,
                   Channel.of("one_tumour_per_patient"),
                   params.OUTDIR,
                   params.cohort_prefix,
                   params.gistic_refgene_file,
                   giab_regions,
                   broad_cutoff,
                   chrom_arms)
        
        INDEPENDENT_COHORT(independent_cohort,
                   estimates_list,
                   Channel.of("independent_tumors"),
                   params.OUTDIR,
                   params.cohort_prefix,
                   params.gistic_refgene_file,
                   giab_regions,
                   broad_cutoff,
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
