# dermatlas_copy_number_nf

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A521.10.6-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

## Usage 
The preferred way to launching is using a bash script so that you can record the revision (-r ) and params file supplied to generate a batch of targetons. This will pin the pipeline to a version based on the GitLab repo and preserve the command that was used to run the pipeline.

Basic Sanger FARM usage
```
module load nextflow/22.04.5
module load singularity
module load /software/team113/modules/modulefiles/tw/0.6.2
nextflow run 'https://gitlab.internal.sanger.ac.uk/team302/tdflow' \
-params-file $PARAMS_FILE \
-with-tower 'https://tower.internal.sanger.ac.uk/api' \
-r v0.0.1 \
-profile cluster
```

## Testing
Pipeline has been built with nf-test to perform unit and some integration tesing

Run tests with 
```
nf-test test 
```
Individual tests with:
```
nf-test test tests/modules/ascat_exomes.nf.test
```