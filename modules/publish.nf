process TSV_TO_EXCEL {
    container "gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/maf:0.6.1"
    publishDir "${params.OUTDIR}/${params.release_version}", mode: params.publish_dir_mode
    
    input: 
    tuple path(file)

    output: 
    path("*.xlsx")

    script:
    """
    Rscript /opt/repo/tsv2xlsx.R $file
    """

}

process GENERATE_README {
    publishDir "${params.OUTDIR}/${params.release_version}", mode: params.publish_dir_mode

    output: 
    path("README_ASCAT_FILES.txt")
    script:
    """
    cat > README_ASCAT_FILES.txt << END

    These directories contain a summary of the results from ASCAT.

    # Subdirectories:

    PLOTS_INDEPENDENT_TUMOURS - penetrance plots include multiple, independent tumours from all patients (IF APPLICABALE)
    PLOTS_ONE_PER_PATIENT - penetrance plots include one tumour per patient


    # Files in each subdirectory:

    README_ASCAT_FILES.txt - this file

    # From all samples used to run ASCAT:
    ascat_excluded_unmatched.tsv - unmatched samples that were excluded
    ascat_low_qual.list - list of samples excluded due to goodness-of-fit < 90

    # For one tumour per patient and independent tumours
    # TSV files are also converted to xlsx files for
    # convenience

    ascat_stats.tsv - ploidy, purity, XX/XY estimates from ASCAT
    sample_purity_ploidy.tsv - ASCAT sample estimated purity and ploidy
    ascat_estimate_files.list - files used to get the ASCAT estimates
    samples2sex.tsv - patient sex from the metadata

    # Directories with plots and segment files:

    PLOTS_ONE_PER_PATIENT/
    PLOTS_INDEPENDENT/ (if applicable)

    *CNfreq.pdf - penetrane plot of CN gain/loss
    *CNfreq.tsv - counts of CN gain/loss in 1Mb windows (used to draw the plots)
    *cn-loh.pdf - frequency plot of copy-neutral loss of heterozygosity
    *cn-loh.tsv - counts of cn-LOH ini 1Mb windows (used to draw the plots)

    samples.list - list of samples included in plots
    *_segments.tsv - segments from all samples included in the plots
    *_cn-loh_segments.tsv - segments with cn-LOH
    *_segfiles.list - files used to draw the CN plots



    END
    """
}