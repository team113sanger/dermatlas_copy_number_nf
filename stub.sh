
module purge
unset R_LIBS
unset R_LIBS_USER

#export SINGULARITY_BINDPATH='/lustre,/software'
nextflow run main.nf \
-params-file params.json \
-c tests/nextflow.config 


nextflow run main.nf \
-params-file params.json \
-c nextflow.config
-profile local