#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
// Repeated data ingestion for whole and subgroups of samples

include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'
include { SPLIT_COHORT_SEXES } from './subworkflows/split_sample_cohort.nf'

include { ASCAT_ANALYSIS } from './subworkflows/ascat_analysis.nf'
include { ANALYSE_SUBCOHORT as ONE_TUMOR_PER_PATIENT } from './subworkflows/analyse_subcohort.nf'
include { ANALYSE_SUBCOHORT as INDEPENDENT_TUMORS } from './subworkflows/analyse_subcohort.nf'

include { TSV_TO_EXCEL; GENERATE_README } from './modules/publish.nf'

workflow {

    // Cohort files 
    bamfiles           = Channel.fromPath(params.bam_files, checkIfExists: true)
    all_pairs          = Channel.fromPath(params.all_samples, checkIfExists: true)
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
    
    // Output the Male and female datasets as sepeate files
    SPLIT_COHORT_SEXES(DERMATLAS_METADATA.out.combined_metadata)
    
    // Perform ASCAT analysis on the entire cohort
    ASCAT_ANALYSIS(DERMATLAS_METADATA.out.combined_metadata,
                   params.outdir,  
                   reference_genome,
                   bait_set,
                   per_chrom_files,
                   gc_file,
                   rt_file,
                   params.cohort_prefix)
    

    if (params.one_per_patient) {
    one_tumor_per_patient = Channel.fromPath(params.one_per_patient, checkIfExists: true)
    ONE_TUMOR_PER_PATIENT(
                          DERMATLAS_METADATA.out.combined_metadata,
                          one_tumor_per_patient,
                          ASCAT_ANALYSIS.out.filtered_outs, 
                          ASCAT_ANALYSIS.out.estimates,
                          'one_tumor_per_patient',
                          "PLOTS_ONE_PER_PATIENT",
                           params.outdir,
                           params.cohort_prefix,
                           params.gistic_refgene_file,
                           giab_regions,
                           broad_cutoff,
                           chrom_arms)
    }

    if (params.independent) {
    independent_tumors = Channel.fromPath(params.independent, checkIfExists: true)
    INDEPENDENT_TUMORS(
                          DERMATLAS_METADATA.out.combined_metadata,
                          independent_tumors,
                          ASCAT_ANALYSIS.out.filtered_outs, 
                          ASCAT_ANALYSIS.out.estimates,
                          'independent_tumors',
                          "PLOTS_INDEPENDENT",
                           params.outdir,
                           params.cohort_prefix,
                           params.gistic_refgene_file,
                           giab_regions,
                           broad_cutoff,
                           chrom_arms)
    }

    // Convert all tab files to tsv. TODO 
    // ASCAT_ANALYSIS.out.freq_tab
    // | concat(ASCAT_ANALYSIS.out.purity)
    // | concat(ASCAT_ANALYSIS.out.summary_stats) 
    // | concat(GISTIC2_ANALYSIS.out.gistic_tabs)
    // | concat(GISTIC2_ANALYSIS.out.sample_summary)
    // | concat(GISTIC2_ANALYSIS.out.cohort_summary)
    // | set { tabular_ch }
    
    // TSV_TO_EXCEL( tabular_ch )
    GENERATE_ASCAT_README()


}
