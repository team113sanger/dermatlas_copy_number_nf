# dermatlas_copy_number_nf

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.04.5-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

dermatlas_copy_number_nf is a bioinfromatics pipeline written in nextflow for performing copy-number alteration (CNA) analysis on cohorts of tumors within the Dermatlas project. 

## Pipeline summary

In brief, the pipeline takes a cohort of samples that have been ingested and preprocessed and:
- Links cohort sample metadata to sample bamfiles and links pairs for each tumor/normal sample.
- Runs ASCAT on each tumor-normal pair, outputting segment calls. 
- Collates summary statistics for the ASCAT runs and removes those samples below a threshold Goodness-of-Fit level 
- Merges the segment calls from ASCAT that pass filtering.
- Runs GISTIC2 to identify regions with significant copy-number alterations (CNAs).
- Filters GISTIC calls to identify those that overlap with ASCAT.

## Inputs 

`bam_files`: a wildcard containing a path to a directory containing a Bamfiles 
`index_files`: a path to the corresponding .bai index files for those BAMS 
Sample metadata: path to a file containing sample PD IDs, tumor normal info, and sex
`tumor_normal_pairs`: path to a file containing a tab-delimited list of matched tumour and normal pairs.

The following reference files, which will be used across pipeline executions are located within the `nextflow.config` file.
`reference_genome`
`bait_set`
`resource_files`
`gc_file`
`rt_file`
`gistic_refgene_file`
`difficult_regions_file`

## Usage 
The recommended way to launch this pipeline is using a wrapper script that records the revision (-r ) and the specific params `json` file supplied for a run. 

Basic Sanger FARM usage:
```
#!/bin/bash
#BSUB -q normal
#BSUB -G cellularoperations
#BSUB -R "select[mem>8000] rusage[mem=8000] span[hosts=1]"
#BSUB -M 8000
#BSUB -oo nf_out.o
#BSUB -eo nf_out.e

PARAMS_FILE="/lustre/scratch125/casm/team113da/users/jb63/nf_cna_testing/params.json"

module load nextflow-23.10.0
module load singularity
module load /software/team113/modules/modulefiles/tw/0.6.2

nextflow run 'https://gitlab.internal.sanger.ac.uk/DERMATLAS/analysis-methods/dermatlas_copy_number_nf' \
-r feature/config_dmemo \
-params-file $PARAMS_FILE \
-c /lustre/scratch125/casm/team113da/users/jb63/nf_cna_testing/nextflow.config \
-profile farm22 
```
This can also 

A usage profile for OpenStack secure-lustre instances is provided. 
`-profile secure-lustre`


## Pipeline visualisation 

```mermaid
%%{init: { 'theme': 'forest' } }%%
flowchart TB
    subgraph " "
    v0["Channel.fromPath"]
    v1["Channel.fromPath"]
    v2["Channel.fromPath"]
    v3["Channel.fromPath"]
    v20["outdir"]
    v21["project_dir"]
    v22["genome"]
    v23["baits"]
    v24["per_chrom_dir"]
    v25["gc_file"]
    v26["rt_file"]
    v46["cohort_prefix"]
    v49["refgenefile"]
    v55["difficult_regions"]
    v56["prefix"]
    end
    subgraph ASCAT_ANALYSIS
    v27([RUN_ASCAT_EXOMES])
    v35([EXTRACT_GOODNESS_OF_FIT])
    v37([SUMMARISE_ASCAT_ESTIMATES])
    v47([CREATE_FREQUENCY_PLOTS])
    v4(( ))
    v36(( ))
    v40(( ))
    end
    subgraph " "
    v28[" "]
    v29[" "]
    v30[" "]
    v31[" "]
    v32[" "]
    v33[" "]
    v34[" "]
    v38[" "]
    v39[" "]
    v45[" "]
    v48[" "]
    v51[" "]
    v52[" "]
    v53[" "]
    v54[" "]
    v58[" "]
    end
    subgraph GISTIC2_ANALYSIS
    v50([RUN_GISTIC2])
    v57([FILTER_GISTIC2_CALLS])
    end
    v0 --> v4
    v1 --> v4
    v2 --> v4
    v3 --> v4
    v20 --> v27
    v21 --> v27
    v22 --> v27
    v23 --> v27
    v24 --> v27
    v25 --> v27
    v26 --> v27
    v4 --> v27
    v27 --> v34
    v27 --> v35
    v27 --> v33
    v27 --> v32
    v27 --> v31
    v27 --> v30
    v27 --> v29
    v27 --> v28
    v27 --> v36
    v27 --> v40
    v35 --> v40
    v36 --> v37
    v37 --> v39
    v37 --> v38
    v37 --> v47
    v40 --> v45
    v46 --> v47
    v40 --> v47
    v47 --> v48
    v49 --> v50
    v40 --> v50
    v50 --> v57
    v50 --> v54
    v50 --> v53
    v50 --> v52
    v50 --> v51
    v55 --> v57
    v56 --> v57
    v57 --> v58
```

## Testing

This pipeline has been built with nf-test framework to generate unit tests and perfom some integration tesing. Small test data is provided within test/testdata and snapshots for outputs of steps have been provided to detect regressions. You can run all tests with:

```
nf-test test 
```
Individual tests with:
```
nf-test test tests/modules/ascat_exomes.nf.test
```