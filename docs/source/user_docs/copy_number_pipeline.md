# Nextflow: Copy number alteration calling pipeline

Copy number alteration calling for DERMATLAS can be run mostly with a single nextflow pipeline in a largely "set-and-forget" manner. This document contains an SOP for configuring and running the pipeline. For a more detailed explanation of the pipeline inputs and requirements for running see the project [README](https://github.com/team113sanger/dermatlas_copy_number_nf/blob/develop/README.md)

## Workflow Overview

1. **Generating pipeline inputs for Dermatlas studies** 
2. **Generating the cohort config file**
3. **Running the pipeline**
4. **Make a release folder**
5. **Post pipeline cleanup**
6. **Troubleshooting**

## Workflow Steps

### 1. Generating pipeline inputs for Dermatlas studies

The study-specific inputs required to run the copy number calling pipeline are: the sample bams for a study's matched tumour-normal pairs; sets of the sample groupings; and the study metadata sheet. See [dematlas analysis setup]() for instructions on how to prepare these.

### 2. Generating the cohort config file

The nextflow pipeline’s config file encodes all the options and inputs we might want to pass to the pipeline. `dermanager projectify` populates it in your project directory as `commands/copynumber_pipe/copy_number.config`, alongside the wrapper script for launching the pipeline, `commands/copynumber_pipe/run_copy_number.sh`. Every project location in the config is read from the variables the project `source_me.sh` exports.

The defaults provided should be suitable for running out of the box but for some pipeline runs there are a handful of parameters that you might consider changing:

- The `cohort_prefix` (which will be used in the labelling of output files)
- The `bam_files` path to the sample bam files obtained in step 1
- The `metadata_manifest` metadata table for the cohort
- A complete list of sample pairs (`all_samples`)
- The subcohorts: a groovy map detailing subsets of the sample list to be grouped cohort level analysis e.g independent tumours
- The output directory to publish results into
- A release version to identify the run outputs if multiple runs end up being run

There is a larger universe of other parameters, specified within the config file that normally won't need changing. These mostly set paths to reference files. 

Should you need one, the config dermanager ships is [`assets/copy_number.config`](https://github.com/team113sanger/dermatlas_copy_number_nf/blob/develop/assets/copy_number.config) in the repository.

### 3. Running the pipeline

Provided that you have set up your project with dermanager, launch the pipeline on the Sanger farm22 LSF from the project directory (the wrapper sources `./source_me.sh`):

```
cd <project_dir> && bsub -e logs/copy_number.e -o logs/copy_number.o < commands/copynumber_pipe/run_copy_number.sh
```

The bsub magic at the start of the wrapper script will send a nextflow “master job”, will watch all other jobs to the oversubscribed queue (where it can live in peace running for a long period without fear of termination). Nextflow will shortly start submitting jobs on your behalf to the relevant queues

If you haven’t initialised your project with dermanager, see "Without the website" in the [README](https://github.com/team113sanger/dermatlas_copy_number_nf/blob/develop/README.md): the wrapper, [`assets/run_copy_number.sh`](https://github.com/team113sanger/dermatlas_copy_number_nf/blob/develop/assets/run_copy_number.sh), documents every variable it needs in its MANUAL ENVIRONMENT OVERRIDES block. Its `REVISION` selects which version of the pipeline to run.

### 4. Post-pipeline cleanup: removing temporary files

The wrapper deletes the `work` directory itself after a successful run (set `DERMATLAS_CLEANUP_WORK_DIR=false` to keep it). A failed run keeps its `work` directory, so a resubmission can `-resume`. See "Toggles" and "Reclaiming disk space" in the README.

## 5. Making release folder

### Releasing ASCAT results

In the Dermatlas project, to aid in the interpretation of ASCAT results, we convert some of the text file outputs to Excel for our scientists and upload both versions to gitlab. We also generate a generic README file and a list of samples used in the analyses. Files are copied to a target directory, which is your local git clone of the PU project on gitlab.

In working directory: `${PROJECTDIR}/analysis/ASCAT/release_v${i}`, where `i` is your release number:

```bash
bash ${PROJECTDIR}/scripts/ASCAT/make_ascat_release.sh ${PROJECTDIR} ${INPUTDIR} ${TARGETDIR}

```
where `${TARGETDIR}` is the path to your PU git clone gistic2 release directory and `${INPUTDIR}` is your release directory.

In gitlab the typical directory structure for releases is:
```
dermatlas_pu3/DNA_projects/${project_name}/analysis/copy_number/ascat/release_v${i}
```

### Releasing GISTIC results

In working directory: `${PROJECTDIR}/analysis/gistic2/release_v${i}` where `i` is your release number.

```bash
source ${PROJECTDIR}/scripts/gistic2/source_me_summarise.sh
bash ${PROJECTDIR}/scripts/gistic2/make_gistic_release.sh ${PROJECTDIR} $PWD ${TARGETDIR}
```
where `${TARGETDIR}` is the path to your PU git repository gistic2 release directory.
In gitlab the directory structure is:
`dermatlas_pu3/DNA_projects/${project_name}/analysis/copy_number/gistic2/release_v${i}`



## 6. Troubleshooting

There are several reasons the pipeline might fail: bugs, the Farm, or misconfiguration. In most cases (especially when you suspect a farm failure), simply resubmitting the pipeline with:

```bash
cd <project_dir> && bsub -e logs/copy_number.e -o logs/copy_number.o < commands/copynumber_pipe/run_copy_number.sh
```

will trigger the nextflow `-resume` directive and the pipeline will pick up where it left off.

Sometimes you might need to modify resources by providing a supplementary field to the nextflow.config file:

```groovy
process {
    withName: ASCAT_EXOMES {
              cpu = 18
              memory = "30G"}
}
```
