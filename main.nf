#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
// Repeated data ingestion for whole and subgroups of samples

include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'
include { SPLIT_COHORT_SEXES } from './subworkflows/split_sample_cohort.nf'

include { ASCAT_ANALYSIS } from './subworkflows/ascat_analysis.nf'
include { ANALYSE_SUBCOHORT as ONE_TUMOR_PER_PATIENT } from './subworkflows/analyse_subcohort.nf'
include { ANALYSE_SUBCOHORT as INDEPENDENT_TUMORS } from './subworkflows/analyse_subcohort.nf'

include { TSV_TO_EXCEL; GENERATE_ASCAT_README } from './modules/publish.nf'

workflow {

    // Cohort files
    bamfiles           = channel.fromPath(params.bam_files, checkIfExists: true)
    all_pairs          = channel.fromPath(params.all_samples, checkIfExists: true)
    patient_md         = channel.fromPath(params.metadata_manifest, checkIfExists: true)
    // Reference files 
    reference_genome   = file(params.reference_genome, checkIfExists: true)
    bait_set           = file(params.bait_set, checkIfExists: true)
    per_chrom_files    = file(params.resource_files, checkIfExists: true)
    gc_file            = file(params.gc_file, checkIfExists: true)
    rt_file            = file(params.rt_file, checkIfExists: true)
    giab_regions       = file(params.difficult_regions_file, checkIfExists: true)
    chrom_arms         = file(params.chrom_arms_file, checkIfExists: true)
    
    // Thresholds
    broad_cutoff       = channel.of(params.gistic_broad_peak_q_cutoff)
    focal_cutoff       = channel.of(params.gistic_focal_q_value_cutoff)
    gof_threshold      = channel.of(params.ascat_goodness_of_fit_threshold)

    // Combine and pivot the metadata so that T/N pair 
    // bams and metadata are a single channel
    log.info("Processing patient metadata and linking with BAM files...")
    DERMATLAS_METADATA(bamfiles, 
                       all_pairs,
                       patient_md)
    
    // Output the Male and Female datasets as seperate files
    
    SPLIT_COHORT_SEXES(DERMATLAS_METADATA.out.combined_metadata)
    // Perform ASCAT analysis on the entire cohort
    log.info("Running ASCAT analysis...")
    ASCAT_ANALYSIS(DERMATLAS_METADATA.out.combined_metadata,
                   reference_genome,
                   bait_set,
                   per_chrom_files,
                   gc_file,
                   rt_file,
                   gof_threshold)
    

    if (params.one_per_patient) {
    log.info("Running ASCAT post-processing for one tumor per patient...")
    one_tumor_per_patient = channel.fromPath(params.one_per_patient, checkIfExists: true)
    ONE_TUMOR_PER_PATIENT(
                          one_tumor_per_patient,
                          ASCAT_ANALYSIS.out.filtered_outs,
                          ASCAT_ANALYSIS.out.estimates,
                          'one_tumour_per_patient',
                          "PLOTS_ONE_PER_PATIENT",
                           params.cohort_prefix,
                           params.gistic_refgene_file,
                           giab_regions,
                           broad_cutoff,
                           focal_cutoff,
                           chrom_arms)
    }

    if (params.independent) {
    log.info("Running ASCAT post-processing for independent cohort...")
    independent_tumors = channel.fromPath(params.independent, checkIfExists: true)
    INDEPENDENT_TUMORS(
                          independent_tumors,
                          ASCAT_ANALYSIS.out.filtered_outs,
                          ASCAT_ANALYSIS.out.estimates,
                          'independent_tumours',
                          "PLOTS_INDEPENDENT",
                           params.cohort_prefix,
                           params.gistic_refgene_file,
                           giab_regions,
                           broad_cutoff,
                           focal_cutoff,
                           chrom_arms)
    }


}
