#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { DERMATLAS_METADATA } from './subworkflows/process_metadata.nf'
include { ASCAT_ANALYSIS } from './subworkflows/ascat_analysis.nf'
// include { GISTIC_ANALYSIS } from './subworkflows/gistic_analysis.nf'

workflow {
    bamfiles   = Channel.fromPath(params.bam_files)
    index_files = Channel.fromPath(params.index_files)
    pair_ids   = Channel.fromPath(params.tumor_normal_pairs)
    patient_md = Channel.fromPath(params.metadata_manifest)
    reference_genome = Channel.of(file(params.reference_genome))
    bait_set = Channel.of(file(params.bait_set))
    allele_files = Channel.of(file(params.resource_files))
    // loci_files = Channel.of(file(params.loci_files)) 
    gc_file = Channel.of(file(params.gc_file))
    rt_file = Channel.of(file(params.rt_file))


    DERMATLAS_METADATA(bamfiles, index_files, pair_ids, patient_md).view()

    ASCAT_ANALYSIS(DERMATLAS_METADATA.out, 
                    params.OUTDIR, 
                    params.PROJECTDIR, 
                    reference_genome,
                    bait_set,
                    allele_files,
                    gc_file,
                    rt_file)
    // ASCAT_ANALYSIS.out.estimates.view()
    // ASCAT_ANALYSIS.out.segments.view()
    // GISTIC_ANALYSIS()
    // GISTIC(segments_list)
    // SUMMARISE_ASCAT_ESTIMATES.out.ascat_sstats[4]
    //  .splitCsv( header: true )
    // RUN_ASCAT_EXOMES.out.segments.map{groupkey, file -> groupkey.target}.view()


}
