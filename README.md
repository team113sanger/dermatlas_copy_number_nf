# dermatlas_copy_number_nf

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.10.6-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

dermatlas_copy_number_nf is a pipeline that performsd copy-number alteration (CNA) analysis on cohorts of tumors within the Dermatlas project. 

## Pipeline summary
In brief the pipeline takes a cohort of samples and
- Links cohort sample metadata to sample bamfiles and pairs tumor/normal sample
- Runs ASCAT on each tumor-normal pair, outputting segment calls. 
- Collates summary statistics for the ASCAT runs and removes those samples below a threshold Goodness-of-Fit
- Merges the segment calls from ASCAT that pass filtering.
- Runs GISTIC2 to identify regions with significant copy-number alterations (CNAs)
- Filters GISTIC calls to identify those that overlap with ASCAT.

## Inputs 

BAM files: path to a collection of Bamfiles 
Index files: path to the corresponding .bai index files for those BAMS 
Sample metadata: path to a file containing sample PD IDs, tumor normal info, and sex
Pair IDs: path to a file containing predefined tumor normal pairs.

**Reference files**
ASCAT 
reference_genome
bait_set
resource_files
gc_file
rt_file

GISTIC

gistic_refgene_file
difficult_regions_file

## Usage 
The recommended way to launch this pipeline is with a wrapper script that records the revision (-r ) and params file supplied for a run. 

Basic Sanger FARM usage
```
PARAMS_FILE=""
module load nextflow/22.04.5
module load singularity
module load /software/team113/modules/modulefiles/tw/0.6.2

nextflow run 'https://gitlab.internal.sanger.ac.uk/DERMATLAS/analysis-methods/dermatlas_copy_number_nf' \
-params-file $PARAMS_FILE \
-with-tower 'https://tower.internal.sanger.ac.uk/api' \
-r develop \
-profile cluster
```

A usage profile for OpenStack secure-lustre instances is provided. 
`-profile secure-lustre`

## Testing
This pipeline has been built with nf-test to perform unit and some integration tesing. 
Test data is provided within test/testdata You can run tests with:
```
nf-test test 
```
Individual tests with:
```
nf-test test tests/modules/ascat_exomes.nf.test
```