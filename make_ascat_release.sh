
input_dir=$1
target_dir=$2

if [ ! -d $input_dir ] || [ ! -w $input_dir ]; then
	echo "No input directory $input_dir or not writeable"
	exit
elif [ ! -d $target_dir ] || [ ! -w $target_dir ]; then
	echo "No target directory $target_dir or not writeable"
	exit
fi

cd $input_dir
echo "PWD is $PWD"


# Make lists of samples used

for f in `find PLOTS_* | grep -v PLOTS_ALL |grep segments.tsv`; do
	outdir=`dirname $f`
	cut -f 1 $f | grep -v Sample | sort -u > $outdir/samples.list
done


## Convert files with gene names into xlsx
#
#export R_LIBS=/nfs/casm/team113da/dermatlas/lib/R-4-2.2; 
#
#for file in `find |grep txt | grep -v README`; do 
#	echo $file
#	/software/team113/dermatlas/R/R-4.2.2/bin/Rscript ../../../scripts/tsv2xlsx.R $file
#done
#
#for file in `find |grep scores.gistic$`; do 
#	echo $file
#	/software/team113/dermatlas/R/R-4.2.2/bin/Rscript ../../../scripts/tsv2xlsx.R $file
#done


# Make a README file

cat > README.txt << END

These directories contain a summary of the results from ASCAT.

# Subdirectories:

PLOTS_INDEPENDENT_TUMOURS - penetrance plots include multiple, independent tumours from all patients (IF APPLICABALE)
PLOTS_ONE_PER_PATIENT - penetrance plots include one tumour per patient


# Files in each subdirextory:
*_segments.tsv - segments from all samples included in the plots
*CNfreq.pdf - penetrane plot of CN gain/loss
*CNfreq.tsv - counts of CN gain/loss in 1Mb windows (used to draw the plots)
*cn-loh.pdf - frequency plot of copy-neutral loss of heterozygosity
*cn-loh.tsv - counts of cn-LOH ini 1Mb windows (used to draw the plots)
samples.list - list of samples included in plots
ascat_low_qual.list - list of samples excluded due to goodness-of-fit < 90

# Other files:
ascat_stats.tsv - ploidy, purity, XX/XY estimates from ASCAT


END

# Copy files to git repository

##rsync -av --exclude *PLOTS_ALL* --exclude *logs* ascat_low_qual.list --exclude PD* $input_dir/ascat_stats.tsv $input_dir/PLOTS_* README.txt $target_dir

#rsync  -av README.txt ascat_low_qual.list ascat_stats.tsv sample_purity_ploidy.tsv PLOTS_I* PLOTS_ONE* $target_dir
rsync  -av --exclude *ascat_estimate_files.list* --exclude *independent_tumours_segfiles.list* --exclude *sample_purity_ploidy.tsv* --exclude *samples2sex* README.txt PLOTS_INDEPENDENT PLOTS_ONE_PER_PATIENT $target_dir
