process RUN_ASCAT_EXOMES {
    input: 
    tuple val(tumor_normal_pair), val(metadata) path(OUTDIR), path(PROJECTDIR)

    script:
    def tum_bam = metadata.
    """"
    echo run_ascat_exome.R \
    --tum_bam $tumbam \
    --norm_bam $normbam \
    --tum_name $tum \
    --norm_name $norm \
    --sex $sexchr \
    --outdir $OUTDIR/$tum-$norm \
    --project_dir $PROJECTDIR
    """
}