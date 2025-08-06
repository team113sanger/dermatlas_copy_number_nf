#!/bin/bash
#BSUB -q oversubscribed
#BSUB -G team113-grp
#BSUB -R "select[mem>8000] rusage[mem=8000] span[hosts=1]"
#BSUB -M 8000

set -euo pipefail
 
export REVISION="0.7.5"
export CONFIG="${PROJECT_DIR}/commands/dermatlas_copy_number.config"
 
# Load module dependencies
module load nextflow-23.10.0
module load /software/modules/ISG/singularity/3.11.4
  
# Create a nextflow job that will spawn other jobs

nextflow pull 'https://github.com/team113sanger/dermatlas_copy_number_nf'

nextflow run 'https://github.com/team113sanger/dermatlas_copy_number_nf' \
-r "${REVISION}" \
-c "${CONFIG}" \
-profile farm22 \
-resume