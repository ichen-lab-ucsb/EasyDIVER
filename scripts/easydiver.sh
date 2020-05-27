
#!/bin/bash

# This is EasyDIVER, a pipeline for Easy pre-processing and Dereplication of In Vitro Evolution Reads

# by Sam Verbanic and Celia Blanco
# contact: samuel.verbanic@lifesci.ucsb.edu or cblanco@chem.ucsb.edu
# Dependencies:
	# pandaseq
	# python

usage="USAGE: bash easydiver.sh -i [-o -p -q -r -T -h -a -e]
where:
	REQUIRED
	-i input directory filepath
        
	OPTIONAL
	-o output directory filepath
	-p forward primer sequence for extraction
	-q reverse primer sequence for extraction
	-a translate to amino acids
	-r retain individual lane outputs
	-T # of threads
	-e extra flags for PANDASeq (use quotes, e.g. \"-L 50\")
	-h prints this friendly message"


# Record start time in seconds to calculate run time at the end
start=`date +%s`

# Test to verify pandaseq is installed and can be found
pandatest=$(which pandaseq)

if [ -z "$pandatest" ];
	then
		echo "ERROR: Pandaseq is not installed or cannot be found - cannot continue"
		echo ""
		exit 1
fi

# Set home directory
hdir=$(pwd)

# Parse arguments and set global variables
while getopts hi:o:p:q:T:e:ra option
do
case "${option}"
in

h) helpm="TRUE"
	printf "%`tput cols`s"|tr ' ' '#'
	echo "$usage"
	printf "%`tput cols`s"|tr ' ' '#'
	exit 1;;
i) inopt=${OPTARG};;
o) outopt=${OPTARG};;
p) fwd=${OPTARG};;
q) rev=${OPTARG};;
T) threads=${OPTARG};;
e) extra=${OPTARG};;
r) slanes="TRUE";;
a) prot="TRUE";;

esac
done

bold=$(tput bold)
normal=$(tput sgr0)

if [ -z $helpm ];
	then
		
		echo "${bold} ______                _____ _______      ________ _____  "
 		echo "|  ____|              |  __ \_   _\ \    / /  ____|  __ \ "
 		echo "| |__   ___  ___ _   _| |  | || |  \ \  / /| |__  | |__) |"
 		echo "|  __| / _ \/ __| | | | |  | || |   \ \/ / |  __| |  _  / "
 		echo "| |___| (_| \__ \ |_| | |__| || |_   \  /  | |____| | \ \ "
 		echo "|______\__,_|___/\__, |_____/_____|   \/   |______|_|  \_\ "
 		echo "                  __/ |"
		echo "                 |___/ ${normal}"
		
		banner()
		{
		  echo "+-------------------------------------------------------------------------------------------------+"
		  printf "| %-95s |\n" "`date`"
		  echo "|                                                                                                 |"
		  printf "|${bold} %-95s ${normal}|\n" "$@"
		  echo "+-------------------------------------------------------------------------------------------------+"
		}
		banner "Welcome to the pipeline for Easy pre-processing and Dereplication of In Vitro Evolution Reads"

fi

# Argument report
# Check arguments, print, exit if necessary w/ message

if [ -z "$inopt" ] && [ -z "$outopt" ] && [ -z $fwd ] && [ -z $rev] && [ -z $threads ] && [ -z $extra ] && [ -z $prot ] && [ -z $slanes ];
	then
		echo ""
		echo "${bold}NO FLAGS PROVIDED. ENTERING PROMPTED INPUT VERSION${normal}"
		echo ""
		echo "${bold}Path to your input directory:${normal}"
		read inopt
		echo ""
		echo "${bold}Path to your output directory (default value /pipeline.output):${normal}"
		read outopt
		echo ""
		echo "${bold}Forward primer sequence for extraction:${normal}"
		read fwd
		echo ""
		echo "${bold}Reverse primer sequence for extraction:${normal}"
		read rev
		echo ""
		echo "${bold}Number of threads desired for computation (default value 1):${normal}"
		read threads
		echo ""
		echo "${bold}Extra flags for PANDAseq (default value “-l 1 -d rbfkms“ ; see manual):${normal}"
		read extras
		echo ""
		echo "${bold}Perform translation into amino acids? (yes / no)${normal}"
		read prot
		if [[ $prot == "yes" ]];
			then
				echo ""
			else
				if [[ $prot == "no" ]];
					then
						echo ""
						unset prot
					else
						echo ""
						unset prot
				fi
		fi
		echo "${bold}Retain output files for individual lanes? (yes / no)${normal}"
		read slanes
		if [[ $slanes == "yes" ]];
			then
				echo ""
			else
				if [[ $slanes == "no" ]];
					then
						echo ""
						unset slanes
					else
						echo ""
						unset slanes
				fi
		fi
		echo ""
fi

if [ -z "$inopt" ];
        then
            printf "%`tput cols`s"|tr ' ' '#'
		echo "ERROR: No input filepath supplied." >&2
		echo "$usage" >&2
		printf "%`tput cols`s"|tr ' ' '#' 
		exit 1
        else
			# define input variable with correct path name
			cd $inopt
			fastqs=$(pwd)
			echo "-----Input directory path: $fastqs"	
                
fi

if [ -z "$outopt" ];
        then
			outdir=$fastqs/pipeline.output
			mkdir $outdir
			echo "-----No output directory supplied. New output directory is: $outdir"
			echo "-----Input directory path: $fastqs" > $outdir/log.txt
			echo "-----Output directory path: $outdir" >> $outdir/log.txt
        else
			# define output variable with correct path name
			mkdir $outopt 2>/dev/null
		cd $outopt
			outdir=$(pwd)
			echo "-----Output directory path: $outdir"
			echo "-----Input directory path: $fastqs" > $outdir/log.txt
			echo "-----Output directory path: $outdir" >> $outdir/log.txt
fi

if [ -z $fwd ];
    then
		echo "-----No forward primer supplied. Extraction will be skipped."
		echo "-----No forward primer supplied." >> $outdir/log.txt
		pval=""
	else
		echo "-----Forward Primer: $fwd"
		echo "-----Forward Primer: $fwd" >> $outdir/log.txt
		pval="-p $fwd"
fi

if [ -z $rev ];
	then
		echo "-----No reverse primer supplied. Extraction will be skipped."
		echo "-----No reverse primer supplied." >> $outdir/log.txt
		qval=""
	else
		echo "-----Reverse Primer: $rev"
		echo "-----Reverse Primer: $rev" >> $outdir/log.txt
		qval="-q $rev"
fi

if [ -z $threads ];
	then
		echo "-----Number of threads not supplied. Proceeding with 1 thread, this could take a while ..."
		echo "-----Number of threads = 1"  >> $outdir/log.txt

		threads=1
	else
		echo "-----Number of threads = $threads"
		echo "-----Number of threads = $threads" >> $outdir/log.txt
fi

if [ -z "$extra" ];
	then
		echo "-----No additional PANDAseq flags supplied."
		echo "-----No additional PANDAseq flags."  >> $outdir/log.txt
		extra=""

	else
		echo "-----Additional PANDAseq flags = $extra"
		echo "-----Additional PANDAseq flags = $extra" >> $outdir/log.txt

fi

if [[ $extra == *"t"* ]]
	then
  		tval=""
  	else
  		tval="-t 0.6"
fi

if [[ $extra == *"l"* ]]
	then
  		lval=""
  	else
  		lval="-l 1"
fi

if [[ $extra == *"d"* ]]
	then
  		dval=""
  	else
  		dval="-d rbfkms"
fi


if [ -z $prot ];
	then
		echo "-----Translation off."
		echo "-----Translation off." >> $outdir/log.txt
	else
		echo "-----Translation needed."
		echo "-----Translation needed." >> $outdir/log.txt
fi

if [ -z $slanes ];
	then
		echo "-----Individual lane outputs will be suppressed."
		echo "-----Individual lane outputs suppressed." >> $outdir/log.txt
	else
		echo "-----Individual lane outputs will be retained."
		echo "-----Individual lane outputs retained." >> $outdir/log.txt
fi

echo ""

# Make sure input directory contains fastqs before proceeding
cd $fastqs
if [[ -z "$(ls -1 *.fastq* 2>/dev/null | grep fastq)" ]] ;
then
	echo "ERROR: Input directory does not contain fastq files"
	exit 1
else
	echo "Input filecheck passed"
	echo ""
fi

# move to working directory
# make output directories
cd $outdir
mkdir counts individual.lanes fastqs fastas histos 2>/dev/null

# loop through reads & process them
for R1 in $fastqs/*R1*
do

	# Define some general use variables
	basename=$(basename ${R1})
	lbase=${basename//_R*}
	sbase=${basename//_L00*}
	R2=${R1//R1_001.fastq*/R2_001.fastq*}

	# Make a 'sample' directory for all analyses
	# and combined lane outputs (aka 'sample' outputs)
	dir=$outdir/individual.lanes/$sbase
	mkdir $dir 2>/dev/null

	 # Make a directory for indiv lane read & histo outputs
	lhist=$dir/histos
	fadir=$dir/fastas
	fqdir=$dir/fastqs
	cdir=$dir/counts        
	mkdir $lhist $fadir $fqdir $cdir 2>/dev/null
	
	# Join reads & extract insert
	echo "Joining $lbase reads & extracting primer..."
	pandaseq -f $R1 -r $R2 -F \
	$pval $qval \
	-w $fqdir/$lbase.joined.fastq $tval -T $threads $extra $lval $dval 2>/dev/null

	# Convert to fasta	
	echo "Converting joined $lbase FASTQ to FASTA..."
	awk 'NR%4 == 1 {print ">" substr($0, 2)} NR%4 == 2 {print}' $fqdir/$lbase.joined.fastq > $fadir/$lbase.joined.fasta

	# Combine sequences from each lane into single files
	echo "Adding $lbase reads to total $sbase reads..."
	cat $fqdir/$lbase.joined.fastq >> $dir/$sbase.joined.fastq
    cat $fadir/$lbase.joined.fasta >> $dir/$sbase.joined.fasta

	# Generate indiv lane  nt length distributions
	if [ -z $slanes ];
        then
        	:
		else
			echo "Generating $lbase nt length distribution for individual lanes..."
			# Length distribution for nt sequences
			awk 'NR%2 == 0 {reads+=1}END{print "#Reads:", reads}' $fadir/$lbase.joined.fasta > $lhist/$lbase.joined.nt.histo
			awk 'NR == 2 {line = $0; min = length($1)} NR > 2 && NR%2 ==0 && length($1) < min {line = $0; min = length($1)} END{print "Min:", min}' $fadir/$lbase.joined.fasta >> $lhist/$lbase.joined.nt.histo
			awk 'NR == 2 {line = $0; counts = length($1)} NR > 2 && NR%2 ==0 && length($1) > max {line = $0; max = length($1)} END{print "Max:", max}' $fadir/$lbase.joined.fasta >> $lhist/$lbase.joined.nt.histo

			# Read Length Histogram:
			echo "#Read Length Histogram:" >> $lhist/$lbase.joined.nt.histo
			echo "Len" "Reads" "%Reads" | column -t >> $lhist/$lbase.joined.nt.histo
			awk 'NR%2 == 0  {reads+=1; a[length($1)]+=1}END{for (i in a) printf "%s %s %.3f%% \n",i, a[i], 100*a[i]/reads}' $fadir/$lbase.joined.fasta | column -t | sort -g -k1  >> $lhist/$lbase.joined.nt.histo

			# Counts for nt lanes
			echo "Calculating unique & total reads for lane $lbase..."
			unique=$(awk 'NR%2 == 0 {seen[$1] += 1} END {print length(seen)}' $fadir/$lbase.joined.fasta)
			total=$(awk 'NR%2 == 0 {tot += 1} END {print tot}' $fadir/$lbase.joined.fasta)
			
			# Collect unique, total and sequences with counts in the counts file
			echo "Collecting unique, total and sequences in file..."
			echo "number of unique sequences = $unique" > $cdir/$lbase.joined.counts.txt
			echo "total number of molecules = $total"   >> $cdir/$lbase.joined.counts.txt
			echo  >>  $cdir/$lbase.joined.counts.txt
			awk -v tot="$total" 'NR%2 == 0 {seen[$1] += 1} END {for (i in seen) printf "%s %s %.3f%% \n", i, seen[i], 100*seen[i]/tot}' $fadir/$lbase.joined.fasta| column -t | sort -n -r -k2 >>  $cdir/$lbase.joined.counts.txt
			echo ""
	fi
done

cd $outdir/individual.lanes

########## CREATE COUNTS FILE FOR DNA ##########

# Loop through directories and generate count files

ls -1 | while read d
do
	test -d "$d" || continue
	# Define variables
	base=$(basename ${d})
	(cd $d ;

	# Calculate unique and total
	echo "Calculating unique & total reads for $base..."
	unique=$(awk 'NR%2 == 0 {seen[$1] += 1} END {print length(seen)}' $base.joined.fasta)
	total=$(awk 'NR%2 == 0 {tot += 1} END {print tot}' $base.joined.fasta)

	# Collect unique, total and sequences with counts in the counts file
	echo "number of unique sequences = $unique" > $outdir/counts/$base\_counts.txt
	echo "total number of molecules = $total"   >> $outdir/counts/$base\_counts.txt
	echo  >>  $outdir/counts/$base\_counts.txt
	awk -v tot="$total" 'NR%2 == 0 {seen[$1] += 1} END {for (i in seen) printf "%s %s %.3f%% \n", i, seen[i], 100*seen[i]/tot}' $base.joined.fasta | column -t | sort -n -r -k2 >>  $outdir/counts/$base\_counts.txt

	# Redirect outputs
	mv $base.joined.fasta $outdir/fastas/$base.joined.fasta
	mv $base.joined.fastq $outdir/fastqs/$base.joined.fastq
	
    )
done

# Cleanup indiv lanes

echo ""

if [ -z $slanes ];
	then
		echo "Cleaning up all individual lane outputs..."
                rm -r $outdir/individual.lanes/
        else
               	echo "Individual lane outputs will be retained"
fi

########## CREATE HISTO FILE FOR DNA ##########

cd $outdir/counts

for file in *counts.txt

do 
	# Generate DNA length distribution for all lanes combined
	echo ""
	echo "Generating ${file//_counts.txt} DNA length distribution..."
	awk 'NR > 3 {reads+=$2}END{print "#Reads:", reads}' $file > ${file//_counts.txt}'_counts_histo.txt'
	awk 'NR == 4 {line = $0; min = length($1)} NR > 4 && length($1) < min {line = $0; min = length($1)} END{print "Min:", min}' $file >> ${file//_counts.txt}'_counts_histo.txt'
	awk 'NR == 4 {line = $0; max = length($1)} NR > 4 && length($1) > max {line = $0; max = length($1)} END{print "Max:", max}' $file >> ${file//_counts.txt}'_counts_histo.txt'

	# Read Length Histogram:
	echo "#Read Length Histogram:" >> ${file//_counts.txt}'_counts_histo.txt'
	echo "Len" "Reads" "%Reads" | column -t >> ${file//_counts.txt}'_counts_histo.txt'
	awk 'NR > 3  {reads+=$2; a[length($1)]+=$2}END{for (i in a) printf "%s %s %.3f%% \n",i, a[i], 100*a[i]/reads}' $file | column -t | sort -g -k1  >> ${file//_counts.txt}'_counts_histo.txt'
	
	mv ${file//_counts.txt}'_counts_histo.txt' ../histos/${file//_counts.txt}'_counts_histo.txt'
	
########## TRANSLATE DNA INTO PEPTIDES ##########

if [ -z $prot ];
	then
		echo "No translation will be performed"
		
	else
	
	# Translat into aa
	echo "Translating ${file//_counts.txt} DNA to peptides..."
	echo $pwd
	python ../../../translator.py $file 
	
	# Print in new file every line except the first 3 (2 with the number of molecules and sequences and town empty lines):
	tail -n +4 ${file//_counts.txt}'_counts.aa.dup.txt' | sort > newfile.txt;
	
	#Calculate total reads
	awk '{totaa+=$2}END{print totaa}' ${file//_counts.txt}'_counts.aa.dup.txt'  > /dev/null
	
	# Remove duplicates and sum abundances:
	awk '{seen[$1]+=$2;totaa+=$2}END{for (i in seen) printf  "%s %s %.3f%%\n", i, seen[i], 100*seen[i]/totaa}' newfile.txt  |column -t | sort -k1 > newfile2.txt;
	
	# Sort following abundance:
	sort newfile2.txt -k2 -n -r > newfile3.txt;
	
	# Print second line:
	val=$(awk 'BEGIN {FS = " "} ; {sum+=$2} END {print sum}' newfile3.txt) ; echo total number of molecules      =     $val | cat - newfile3.txt > newfile4.txt;
	
	# Print first line:
	val=$(cat newfile3.txt | wc -l) ; echo number of unique sequences     =     $val | cat - newfile4.txt > newfile5.txt;
	
	# Print third (empty) line:
	awk 'NR==3 {print ""} 1' newfile5.txt > ${file//_counts.txt}'_counts.aa.txt';
	
	# Remove every temp file:
	rm newfile.txt; rm newfile2.txt; rm newfile3.txt; rm newfile4.txt; rm newfile5.txt
	rm ${file//_counts.txt}'_counts.aa.dup.txt'

########## CREATE HISTO FILE FOR PEPTIDES ##########

	# Generate peptide length distribution for all lanes combined
	echo "Generating ${file//_counts.txt} aa length distribution..."
	awk 'NR > 3 {reads+=$2}END{print "#Reads:", reads}' ${file//_counts.txt}'_counts.aa.txt' > ${file//_counts.txt}'_counts.aa_histo.txt'
	awk 'NR == 4 {line = $0; min = length($1)} NR > 4 && length($1) < min {line = $0; min = length($1)} END{print "Min:", min}' ${file//_counts.txt}'_counts.aa.txt' >> ${file//_counts.txt}'_counts.aa_histo.txt'
	awk 'NR == 4 {line = $0; max = length($1)} NR > 4 && length($1) > max {line = $0; max = length($1)} END{print "Max:", max}' ${file//_counts.txt}'_counts.aa.txt' >> ${file//_counts.txt}'_counts.aa_histo.txt'

	# Read Length Histogram:
	echo "#Read Length Histogram:" >>  ${file//_counts.txt}'_counts.aa_histo.txt'
	echo "Len" "Reads" "%Reads" | column -t >>  ${file//_counts.txt}'_counts.aa_histo.txt'
	awk 'NR > 3  {reads+=$2; a[length($1)]+=$2}END{for (i in a) printf "%s %s %.3f%% \n",i, a[i], 100*a[i]/reads}' ${file//_counts.txt}'_counts.aa.txt' | column -t | sort -g -k1  >>  ${file//_counts.txt}'_counts.aa_histo.txt'

fi
	
done

cd ..

if [ -z $prot ];
	then
		:
	else
		mkdir counts.aa
		mv counts/*aa.txt counts.aa/
		mv counts/*aa.dup.txt counts.aa/
		mv counts/*aa_histo.txt histos/
fi

########## CREATE LOG FILE FOR DNA ##########

if [ -z $prot ];

	then

		cd ..

		echo ""  >> $outdir/log.txt
		echo "sample" "fastq_R1" "fastq_R2" "unique_nt" "total_nt" "recovered_nt(%)"| column -t > $outdir/log_temp1.txt

		for R1 in *R1*
		do
			basename=$(basename ${R1})
			lbase=${basename//_R*}
			sbase=${basename//_L00*}
			R2=${R1//R1_001.fastq*/R2_001.fastq*}
	
			echo $sbase \
			$(cat $R1 | zcat | awk 'END {print NR/4}') \
			$(cat $R2 | zcat | awk 'END {print NR/4}')  \
			$(cat ${outdir}/counts/$sbase\_counts.txt | awk 'BEGIN {ORS=" "}; NR==1{print $6}' ) \
			$(cat ${outdir}/counts/$sbase\_counts.txt | awk 'BEGIN {ORS=" "}; NR==2{print $6}' ) \
			| column -t >> $outdir/log_temp2.txt		
		done

		awk '{ printf "%s %.2f%%\n", $0, 100*$5/$2 }' $outdir/log_temp2.txt | column -t >> $outdir/log_temp1.txt
		awk  '{print }' $outdir/log_temp1.txt | column -t >> $outdir/log.txt

		rm $outdir/log_temp1.txt
		rm $outdir/log_temp2.txt

	else


########## CREATE LOG FILE FOR DNA AND PEPTIDE SEQUENCES ##########

		cd ..

		echo ""  >> $outdir/log.txt
		echo "sample" "fastq_R1" "fastq_R2" "unique_nt" "total_nt" "recovered_nt(%)" "unique_aa" "total_aa" "recovered_aa(%)"| column -t > $outdir/log_temp1.txt

		for R1 in *R1*
		do

			basename=$(basename ${R1})
			lbase=${basename//_R*}
			sbase=${basename//_L00*}
			R2=${R1//R1_001.fastq*/R2_001.fastq*}
	
			echo $sbase \
			$(cat $R1 | zcat | awk 'END {print NR/4}') \
			$(cat $R2 | zcat | awk 'END {print NR/4}')  \
			$(cat ${outdir}/counts/$sbase\_counts.txt | awk 'BEGIN {ORS=" "}; NR==1{print $6}' ) \
			$(cat ${outdir}/counts/$sbase\_counts.txt | awk 'BEGIN {ORS=" "}; NR==2{print $6}' ) \
			$(cat ${outdir}/counts.aa/$sbase\_counts.aa.txt | awk 'BEGIN {ORS=" "}; NR==1{print $6}' ) \
			$(cat ${outdir}/counts.aa/$sbase\_counts.aa.txt | awk 'BEGIN {ORS=" "}; NR==2{print $6}' ) \
			| column -t >> $outdir/log_temp2.txt
					
		done

		awk '{ printf "%s %s %s %s %s %.2f%% %s %s %.2f%%\n", $1, $2, $3, $4, $5, 100*$5/$2, $6, $7, 100*$7/$2 }' $outdir/log_temp2.txt | column -t >> $outdir/log_temp1.txt
		awk  '{print }' $outdir/log_temp1.txt | column -t >> $outdir/log.txt

		rm $outdir/log_temp1.txt
		rm $outdir/log_temp2.txt

fi

# Record end time in seconds to calculate run time at the end
end=`date +%s`

# Calculate run time
runtime=$((end-start))
echo ""
echo "Run time:" $runtime
