include { RUN_ASCAT_EXOMES; SUMMARISE_ASCAT_ESTIMATES; CREATE_FREQUENCY_PLOTS; EXTRACT_GOODNESS_OF_FIT } from '../modules/ascat.nf'
include { GISTIC2_ANALYSIS } from '../subworkflows/gistic2_analysis.nf'

workflow ANALYSE_COHORT {
    take: 
    ascat_subgroup
    estimates_list
    analysis_type
    output_dir
    cohort_prefix
    gistic_refgene_file
    giab_regions
    cutoff
    chrom_arms
    
    main:
        
    SUMMARISE_ASCAT_ESTIMATES(estimates_list, 
                              Channel.of(analysis_type))
    
    
    ascat_subgroup
    | map { meta, segments, gistic -> segments }
    | collectFile(name: 'combined_segment_file.txt', 
                 keepHeader: true,
                 storeDir: "${params.OUTDIR}/ASCAT/${params.release_version}/${analysis_type}", 
                 skip: 1)
    | set { segment_summary }

    ascat_subgroup
    | map { meta, segments, gistic -> gistic }
    | collectFile(name: "${analysis_type}_segs.tsv", 
       storeDir: "${params.OUTDIR}/ASCAT/${params.release_version}/${analysis_type}")
    | set { gistic_ch }
    
    ascat_subgroup
    | collectFile(name: "samples2sex.txt", 
      storeDir: "${params.OUTDIR}/ASCAT/${params.release_version}/${analysis_type}"){
           meta, segments, gistic ->
        ["samples2sex.txt", "${meta["tumor"]}\t${meta["sexchr"][0]}\n"]
    }
    | set { sex2chr_ch }
  

    CREATE_FREQUENCY_PLOTS(segment_summary,
                           SUMMARISE_ASCAT_ESTIMATES.out.purity,
                           sex2chr_ch, 
                           cohort_prefix,
                           analysis_type)

    GISTIC2_ANALYSIS(gistic_ch,
                    CREATE_FREQUENCY_PLOTS.out.processed_segments, 
                    gistic_refgene_file, 
                    giab_regions,
                    cohort_prefix,
                    cutoff,
                    chrom_arms)
    
}