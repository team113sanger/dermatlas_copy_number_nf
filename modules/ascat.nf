process RUN_ASCAT_EXOMES {
    publishDir "${params.OUTDIR}", mode: 'copy'
    input: 
    tuple val(metadata), path(normbam), path(tumbam)
    path(outdir)
    path(project_dir)
    
    output:


    script:
    def tum = "${metadata.tumor}"
    def norm = "${metadata.normal}"
    def sexchr = "${metadata.sexchr}"
    
    """
    echo run_ascat_exome.R \
    --tum_bam $tumbam \
    --norm_bam $normbam \
    --tum_name $tum \
    --norm_name $norm \
    --sex $sexchr \
    --outdir $tum-$norm \
    --project_dir $project_dir
    """
}