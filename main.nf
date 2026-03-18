#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
// Repeated data ingestion for whole and subgroups of samples

include { DERMATLAS_METADATA } from './subworkflows/local/process_metadata.nf'
include { SPLIT_COHORT_SEXES } from './subworkflows/local/split_sample_cohort.nf'

include { ASCAT_ANALYSIS } from './subworkflows/local/ascat_analysis.nf'
include { ANALYSE_SUBCOHORT } from './subworkflows/local/analyse_subcohort.nf'

include { UTILS_NEXTFLOW_PIPELINE } from './subworkflows/nf-core/utils_nextflow_pipeline/main.nf'

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
    ensembl_transcript = file(params.ensembl_transcript, checkIfExists: true)
    cancer_gene_list   = file(params.cancer_gene_list, checkIfExists: true)
    oncokb_file        = file(params.oncokb_file, checkIfExists: true)
    
    // Thresholds (value channels so they can be reused)
    broad_cutoff       = Channel.value(params.gistic_broad_peak_q_cutoff)
    focal_cutoff       = Channel.value(params.gistic_focal_q_value_cutoff)
    gof_threshold      = Channel.value(params.ascat_goodness_of_fit_threshold)
    log2thresholds     = Channel.value(params.gistic_log2_thresholds)

    // Combine and pivot the metadata so that T/N pair 
    // bams and metadata are a single channel
    log.info("Processing patient metadata and linking with BAM files...")
    DERMATLAS_METADATA(bamfiles, 
                       all_pairs,
                       patient_md)
    
    // Output the Male and Female datasets as seperate files
    
    SPLIT_COHORT_SEXES(DERMATLAS_METADATA.out.combined_metadata)
    // Perform ASCAT analysis on valid-sex samples only
    log.info("Running ASCAT analysis...")
    ASCAT_ANALYSIS(SPLIT_COHORT_SEXES.out.valid_metadata,
                   reference_genome,
                   bait_set,
                   per_chrom_files,
                   gc_file,
                   rt_file,
                   gof_threshold)
    

    if (params.subcohorts) {
        log.info("Running ASCAT post-processing for subcohorts: ${params.subcohorts.keySet().join(', ')}...")

        // Create channel of (subcohort_name, sample_list_file, plot_dir) tuples from params.subcohorts map
        // Each subcohort entry should have: sample_list and plot_dir
        cohort_sample_sets = Channel.fromList(
            params.subcohorts.collect { subcohort, config ->
                tuple(subcohort, file(config.sample_list, checkIfExists: true), config.plot_dir)
            }
        )

        ANALYSE_SUBCOHORT(
            cohort_sample_sets,
            ASCAT_ANALYSIS.out.filtered_outs,
            ASCAT_ANALYSIS.out.estimates,
            params.cohort_prefix,
            params.gistic_refgene_file,
            giab_regions,
            broad_cutoff,
            focal_cutoff,
            chrom_arms,
            ensembl_transcript,
            cancer_gene_list,
            oncokb_file,
            log2thresholds
        )
    }

    // Run nf-core utility checks (runs unconditionally)
    UTILS_NEXTFLOW_PIPELINE(
        params.print_version,
        params.dump_parameters,
        params.outdir,
        params.check_conda_channels
    )

}
