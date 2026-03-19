#!/bin/bash
#BSUB -q oversubscribed
#BSUB -G team113-grp
#BSUB -R "select[mem>8000] rusage[mem=8000] span[hosts=1]"
#BSUB -M 8000

set -euo pipefail

export REVISION="1.1.0"
export CONFIG="${PROJECT_DIR}/commands/copy_number.config"

# Create isolated pipeline directory
PIPELINE_DIR="${PROJECT_DIR}/copy_number_pipeline"
mkdir -p "${PIPELINE_DIR}"

# Set isolated Nextflow directories
export NXF_WORK="${PIPELINE_DIR}/work"
export NXF_TEMP="${PIPELINE_DIR}/tmp"
mkdir -p "${NXF_WORK}" "${NXF_TEMP}"

# Load module dependencies
module load nextflow-23.10.0
module load /software/modules/ISG/singularity/3.11.4

# Change to pipeline directory so .nextflow.log goes here
cd "${PIPELINE_DIR}"

# Create a nextflow job that will spawn other jobs

nextflow pull 'https://github.com/team113sanger/dermatlas_copy_number_nf'

nextflow run 'https://github.com/team113sanger/dermatlas_copy_number_nf' \
-r "${REVISION}" \
-c "${CONFIG}" \
-profile farm22 \
-resume \
-work-dir "${NXF_WORK}"