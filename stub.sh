
module purge
unset R_LIBS
unset R_LIBS_USER

#export SINGULARITY_BINDPATH='/lustre,/software'
module load dermatlas-ascat/3.1.2__v0.1.1 
echo $R_LIBS
module load nextflow
nextflow run main.nf \
-params-file params.json \
-stub-run \
-c nextflow.config

module load alleleCount/4.3.0
nextflow run main.nf \
-params-file params.json \
-c nextflow.config \
-profile cluster