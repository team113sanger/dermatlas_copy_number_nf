#!/usr/bin/env Rscript
source("/opt/repo/renv/activate.R")

library(dplyr)
library(purrr)
library(tidyr)

estimate_files <- list.files(path = ".", 
                            full.names = TRUE, 
                            pattern = "ASCAT.*.tsv")

names(estimate_files) <- basename(estimate_files)

read_stats_file <- function(file){
    read.delim(file, sep = "\t", header = FALSE, 
                col.names = c("key", "value"))
}

map_dfr(estimate_files, read_stats_file,.id = "File") |> 
pivot_wider(names_from = key, values_from = value) |> 
mutate(File = paste0("../../", File)) |>
write.table("ascat_stats.tsv", 
            sep = "\t",quote = FALSE, row.names = FALSE)
