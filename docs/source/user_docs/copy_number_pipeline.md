# Nextflow: Copy number variant calling pipeline

Copy number variant calling for DERMATLAS can be run mostly with a single nextflow pipeline in a largely "set-and-forget" manner to reproduce the manual steps detailed in the ASCAT and GISTIC2 documentation. This document contains an overview of how to configure and run the pipeline; for a more detailed explanation of the pipeline inputs and requirements for running can be found within the project [README](https://gitlab.internal.sanger.ac.uk/DERMATLAS/analysis-methods/dermatlas_copy_number_nf/-/blob/develop/README.md?ref_type=heads)

## Workflow Overview

1. **Generating the pipeline inputs**
2. **Generating the cohort config file**
3. **Running the pipeline**
4. **Make a release folder**

## Workflow Steps

Two sets of inputs are required to run the copy number calling pipeline - the sample bams for a studies matched tumour-normal pairs and the sample groupings.

### 1. Generating the pipeline inputs

**Note:** If you have already staged your BAM files during the Dermatlas project setup steps, you can skip this section.

Sample bams can be retrieved by copying over from nst_links like so:

```bash
export PROJECT=2864
export PROJECTDIR=/lustre/scratch125/casm/team113da/projects/dermatlas_pu4_project_dir/6674_2864_Angioleiomyoma_WES/


# Copy the files to a bam sub-directory in your project directory
# NOTE: the inserted "." indicates where to preserve the directory path when copying over)

rsync --dry-run -avRL /nfs/cancer_ref01/nst_links/live/$PROJECT/./*/*bam* $PROJECTDIR/bams/
```

Sample grouping generation is detailed in the somatic variant calling pipeline documentation.

### 2. Generating the cohort config file

The config file encodes all of the options and inputs we might want to pass to the pipeline. For most pipeline runs there are several parameters that need to be changed to get things going:

- The cohort prefix (which will be used in the labelling of output files)
- The path to the sample bam files generated in step 1
- The metadata table for the cohort
- The one_per_patient, independent tumours and all-sample sample lists
- The output directory to publish results into
- A release version to identify the run outputs if multiple runs end up being run

Good practice is to modify these parameters with environmental variables e.g. `${VARIABLE}` and then have the nextflow script decode them.

Feel free to take the generic config file below for your run - ordinarily this won't need changing.

There is an extensive set of other parameters are specified, but won't normally need changing. These are mostly modify which steps are included in a pipeline run and paths to reference files. For convenience of maintaining the pipeline in a way that in can be run on or off farm22, most of the reference files are stored in:

```
/lustre/scratch124/casm/team113/secure-lustre/resources/dermatlas
```

#### Generic config file

```groovy
params {
    outdir = "analysis"
    cohort_prefix = "${STUDY}_${PROJECT}_${COHORT}"
    bam_files = "${PROJECT_DIR}/bams/**.bam"
    all_samples = "${PROJECT_DIR}/metadata/${STUDY}_${PROJECT}-analysed_matched.tsv"
    independent = "${PROJECT_DIR}/metadata/${STUDY}_${PROJECT}-independent_tumours_matched.tsv"
    one_per_patient = "${PROJECT_DIR}/metadata/${STUDY}_${PROJECT}-one_tumour_per_patient_matched.tsv"
    metadata_manifest = "${PROJECT_DIR}/metadata/7651-7652_METADATA_Superficial_acral_fibromyxoma_v20241218.tsv"
    release_version = "version1"

}
```

### 3. Running the pipeline

Once you have your config file ready, you just want a quick means of launching the pipeline. Modify and save this wrapper script, updating the config file and desired log file locations.

The `-r` option specifies which version of the pipeline you'd like to run. Normally you should find the latest tagged version.

#### Example wrapper script: run_copy_number_calling.sh

```bash
#!/bin/bash
#BSUB -q oversubscribed
#BSUB -G team113-grp
#BSUB -R "select[mem>8000] rusage[mem=8000] span[hosts=1]"
#BSUB -M 8000
#BSUB -oo <YOUR_PROJECT_DIR>/analysis/logs/copy_number_variants_pipeline_%J.o
#BSUB -eo <YOUR_PROJECT_DIR>/analysis/logs/copy_number_variants_pipeline_%J.e

set -euo pipefail

export COHORT="DEMO"
export REVISION="0.7.5"
export CONFIG="your/location.config"

# Load module dependencies
module load nextflow-23.10.0
module load /software/modules/ISG/singularity/3.11.4

# Create a nextflow job that will spawn other jobs
nextflow run 'https://github.com/team113sanger/dermatlas_copy_number_nf' \
-r "${REVISION}" \
-c "${CONFIG}" \
-profile farm22 \
-resume
```

Before running the pipeline, you can load your project's environmental variables:

```bash
source source_me.sh
```

If you called the script `run_copy_number_calling.sh` then you'll be able to submit:

```bash
bsub < run_copy_number_calling.sh
```

The bsub magic at the start of the wrapper script sends the nextflow master job to the oversubscribed queue (where it can live in peace running for a long period without fear of termination) and nextflow will start submitting jobs on your behalf to the relevant queues.

## Troubleshooting

There are several reasons the pipeline might fail: bugs, the Farm, or misconfiguration. In most cases (especially when you suspect a farm failure), simply resubmitting the pipeline with:

```bash
bsub < run_copy_number_calling.sh
```

will trigger the nextflow `-resume` directive and the pipeline will pick up where it left off.

Sometimes you might need to modify resources by providing a supplementary fields to the nextflow.config file:

```groovy
process {
    withName: ASCAT_EXOMES {
              cpu = 18
              memory = "30G"}
}
```

### Post-pipeline cleanup: removing temporary files

Once you have successfully run the pipeline and are happy with your results, you can tidy your work area by removing the intermediate files in the `work` directory.

```bash
rm -rf work
```

## Releasing Results

### Releasing ASCAT results

To make viewing the ASCAT results easier, we convert some of the text files to Excel and upload both versions to gitlab. We also provide a generic README file and a list of samples used in the analyses. Files are copied to a target directory, which is your local git clone of the PU project on gitlab.

```bash
# Working directory: ${PROJECTDIR}/analysis/ASCAT/release_v${i} # where $i is your release number
bash ${PROJECTDIR}/scripts/ASCAT/make_ascat_release.sh ${PROJECTDIR} ${INPUTDIR} ${TARGETDIR}
# where ${TARGETDIR} is the path to your PU git clone gistic2 release directory
# and ${INPUTDIR} is your release directory.
```

In gitlab the typical directory structure for releases is:
```
dermatlas_pu3/DNA_projects/${project_name}/analysis/copy_number/ascat/release_v${i}
```

### Releasing GISTIC results

```bash
# Working directory: ${PROJECTDIR}/analysis/gistic2/release_v${i}
# where $i is your release number.
# make_gistic_release.sh was formerly make_gistic_release_v3.sh for PU4

source ${PROJECTDIR}/scripts/gistic2/source_me_summarise.sh
bash ${PROJECTDIR}/scripts/gistic2/make_gistic_release.sh ${PROJECTDIR} $PWD ${TARGETDIR}

# where ${TARGETDIR} is the path to your PU git repository gistic2 release directory.
# In gitlab the directory structure is:
# dermatlas_pu3/DNA_projects/${project_name}/analysis/copy_number/gistic2/release_v${i}
```
