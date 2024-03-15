#!/bin/bash

# This script will create bsub commands for a DERMATLAS
# cohort and submit the jobs to the farm

PROJECTDIR=$1
OUTDIR=$2

SCRIPTDIR=$PROJECTDIR/scripts
MEM=35000
#RSCRIPT="/software/team113/dermatlas/R/R-4.2.2/bin/Rscript"
RSCRIPT="Rscript"
ASCAT_MODULE="dermatlas-ascat/3.1.2__v0.1.1"

#export R_LIBS=/nfs/casm/team113da/dermatlas/lib/R-4-2.2
#export SINGULARITY_BINDPATH="/lustre,/software"

# Check positional arguments

if [[ -z $PROJECTDIR || -z $OUTDIR ]]; then
	echo "Usage: $0 /path/to/project/dir /path/to/output/dir"
	exit
fi


# Check if directories and Rscript exist

for dir in $PROJECTDIR $OUTDIR $SCRIPTDIR $PROJECTDIR/bams; do
	if [[ ! -d $dir ]]; then
		echo "No such directoru: $dir"
		exit;
	fi
done

if [[ ! -e $SCRIPTDIR/ASCAT/run_ascat_exome.R ]]; then
	echo "Can't find $SCRIPTDIR/ASCAT/run_ascat_exome.R"
	exit
fi

# Get a list of samples that passed QC

sample_list=(`dir $PROJECTDIR/metadata/*_tumour_normal_submitted_caveman.txt`)

if [[ ${#sample_list[@]} > 1 ]]; then
	echo "Found more than one list of submitted samples $samplelist"
	exit
elif [[ ${#sample_list[@]} == 0 ]]; then
	echo "File not found: $PROJECTDIR/metadate/*tumour_normal_submitted_caveman.txt"
	exit
else
	sample_list=${sample_list[0]}
	echo "sample_list file: $sample_list"
fi

# Check metadata file

metadata_file=(`dir $PROJECTDIR/metadata/*_METADATA_*.t*`)

if [[ ${#metadata_file[@]} > 1 ]]; then
	echo "Found more than one metadata file $metadata_file"
	exit
elif [[ ${#metadata_file[@]} == 0 ]]; then
	echo "File not found: $PROJECTDIR/metadate/*_METADATA_*.t*"
	exit
else
	metadata_file=${metadata_file[0]}
	echo "metadata_file file: $metadata_file"
fi


# Get a list of sample and sex

info=$PROJECTDIR/metadata/allsamples2sex.tsv

if [[ ! -e $info ]]; then
	echo "Required file missing: $info. Creating file from $metadata_file."
 	#cat $metadata_file | cut -f 6,11,22,23 > $info  # PU1 formatted differently!
 	#cat $metadata_file | cut -f 9,14,25,26 > $info
 	cat $metadata_file | cut -f 9,15,26,27 > $info
fi

if [[ -e $info ]]; then
	awk '$2=="F"' $info | cut -f 3 | xargs -i grep {} $sample_list | sort -u | grep -v PDv38is_wes_v2 > $OUTDIR/ascat_pairs_female.tsv
	awk '$2=="M"' $info | cut -f 3 | xargs -i grep {} $sample_list | sort -u | grep -v PDv38is_wes_v2 > $OUTDIR/ascat_pairs_male.tsv
	cat  $info | cut -f 3 | xargs -i grep {} $sample_list | sort -u | grep PDv38is_wes_v2 > $OUTDIR/ascat_excluded_unmatched.tsv
else
	echo "Problem: cannot locate or create: $info"
	exit
fi

# Submit ASCAT jobs from output directory

cd $OUTDIR

for sex in male female; do 
	for tum in `cut -f 1 ascat_pairs_${sex}.tsv`; do
		norm=`grep $tum ascat_pairs_${sex}.tsv | cut -f 2`
		if [[ -z "$norm" ]]; then
			echo "Can't find normal for $tum"
			exit
		fi
		mkdir -p $tum-$norm/logs
		cd $tum-$norm
		
		# Check that BAMs exist
		tumbam=$PROJECTDIR/bams/$tum/$tum.sample.dupmarked.bam
		normbam=$PROJECTDIR/bams/$norm/$norm.sample.dupmarked.bam
		if [[ ! -e $tumbam || ! -e $normbam ]]; then
			echo "Missing one or more BAMs: $tumbam $normbam"
			exit
		fi
	
		if [[ $sex == "male" ]]; then
			sexchr="XY"
			echo "$sex XY"
		else
			sexchr="XX"
			echo "$sex XX"
		fi

		##cmd="module load alleleCount/4.3.0; $RSCRIPT $SCRIPTDIR/ASCAT/run_ascat_exome.R --tum_bam $tumbam --norm_bam $normbam --tum_name $tum --norm_name $norm --sex $sexchr --outdir $OUTDIR/$tum-$norm --project_dir $PROJECTDIR"
		cmd="export SINGULARITY_BINDPATH='/lustre,/software'; module load $ASCAT_MODULE; $RSCRIPT $SCRIPTDIR/ASCAT/run_ascat_exome.R --tum_bam $tumbam --norm_bam $normbam --tum_name $tum --norm_name $norm --sex $sexchr --outdir $OUTDIR/$tum-$norm --project_dir $PROJECTDIR"

		echo $cmd

		bsub -e logs/$tum-$norm.e -o logs/$tum-$norm.o -q normal -M $MEM -R "select[mem>$MEM && hname != 'node-14-15'] rusage[mem=$MEM]" "$cmd"
		cd $OUTDIR
	done
done

