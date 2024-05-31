process REFORMAT_TSV {
    publishDir "${params.OUTDIR}", mode: 'copy'
    container 'gitlab-registry.internal.sanger.ac.uk/dermatlas/analysis-methods/ascat/feature/nf_image:d84fa3ad'
    
    input: 
    path(infile)
    
    output: 
    path("*.xlsx")

    script:
    """
    #!/usr/bin/env Rscript
    library(writexl)
    library(stringr)
    library(dplyr)

    outfile <- paste0(sub(".tsv|.txt", "", $infile) ,".xlsx")
    print(paste("Output file is", outfile))


    max <- max(count.fields($infile, sep = "\t"))
    tsv_file <- read.table($infile, header = F, sep = "\t", 
                            quote = "", stringsAsFactors = F, 
                            comment.char = "", check.names = F, 
                            col.names = paste0("V",seq_len(max)), fill = T)

    write_xlsx(tsv_file, path = outfile, col_names = F, format_headers = F)
    """

}