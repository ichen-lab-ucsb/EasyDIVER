#!/bin/bash

# This is a pipeline for joining sequence reads and extracting primers

# by Sam Verbanic and Celia Blanco
# contact: samuel.verbanic@lifesci.ucsb.edu or cblanco@chem.ucsb.edu
# Dependencies:
	# bioconda
	# pandaseq
	# libtool
	# bzip2
	# seqkit
	# bbmap

#Example:
# bash proto.pipeline.v4.sh -i ./ -o ./output_CB -p GGGAAAGCGA -q AGAAAAACGG -T 14 -a

usage="USAGE: bash proto.pipeline.v4.sh -i [-o -p -q -r -T -h -a]
where:
	REQUIRED
    -i input directory filepath
        
	OPTIONAL
	-o output directory filepath
    -p forward primer sequence for extraction
    -q reverse primer sequence for extraction
	-r retain individual lane outputs
	-T # of threads
	-h prints this friendly message
	-a translate to amino acids"

# set home directory
hdir=$(pwd)

# parse arguments and set global variables
while getopts hi:o:p:q:T:r:a option
do
case "${option}"
in

h) 	helpm="TRUE"
	printf "%`tput cols`s"|tr ' ' '#'
	echo "$usage"
	printf "%`tput cols`s"|tr ' ' '#'
	exit 1;;
r)	slanes="TRUE";;
i) inopt=${OPTARG};;
o) outopt=${OPTARG};;
p) fwd=${OPTARG};;
q) rev=${OPTARG};;
T) threads=${OPTARG};;
a) prot="TRUE";;

esac
done

# argument report
# check arguments, print, exit if necessary w/ message
if [ -z $helpm ];
	then
		printf "%`tput cols`s"|tr ' ' '#'
		echo "-----Welcome to the Unnamed Chen Lab Pipeline!-----"
		echo "--------You passed the following arguments---------"
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
                outdir=$hdir/pipeline.output
                mkdir $outdir
		echo "-----No output directory supplied. New output directory is: $outdir"
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
                echo "-----WARNING: No forward primer supplied - extraction will be skipped."
	else
		echo "-----Forward Primer: $fwd"
		echo "-----Forward Primer: $fwd" >> $outdir/log.txt
fi

if [ -z $rev ];
        then
                echo "-----WARNING: No reverse primer supplied - extraction will be skipped."
	else
		echo "-----Reverse Primer: $rev"
		echo "-----Reverse Primer: $rev" >> $outdir/log.txt
fi

if [ -z $slanes ];
        then
                echo "-----Individual lane outputs will be suppressed."
                echo "-----Individual lane outputs suppressed." >> $outdir/log.txt
        else
                echo "-----Individual lane outputs will be retained."
                echo "-----Individual lane outputs retained." >> $outdir/log.txt
fi

if [ -z $threads ];
	then
		echo "-----# of threads undefined; proceeding with 1 thread, this could take a while..."
		echo "-----# of threads = 1"  >> $outdir/log.txt

		threads=1
	else
		echo "-----# of threads = $threads"
		echo "-----# of threads = $threads" >> $outdir/log.txt
fi

if [ -z $prot ];
        then
                echo "-----Translation off."
                echo "-----Translation off." >> $outdir/log.txt
        else
                echo "-----Translation on."
                echo "-----Translation on." >> $outdir/log.txt
fi

# Make sure input directory contains fastqs before proceeding
cd $fastqs
if [[ -z "$(ls -1 *.fastq* 2>/dev/null | grep fastq)" ]] ;
then
	echo "ERROR: Input directory does not contain fastq files."
	exit 1
else
	echo "Input filecheck passed."
fi


# move to working directory
# make output directories
cd $outdir
mkdir counts joined.reads fastqs fastas histos 2>/dev/null

# loop through reads & process them
for R1 in $fastqs/*R1*
do

	# Define some general use variables
        ## these will always be set for standard Illumina naming schemes
        ## it will pretty much break if anything else is used.
        ## we can think about making a sloppy alternative for whatever weird names people choose.
        basename=$(basename ${R1})
        lbase=${basename//_R*}
        sbase=${basename//_L00*}
        R2=${R1//R1_001.fastq*/R2_001.fastq*}

        # make a 'sample' directory for all analyses
        # and combined lane outputs (aka 'sample' outputs)
        dir=$outdir/joined.reads/$sbase
        mkdir $dir 2>/dev/null

         # make a directory for indiv lane read & histo outputs
        ldir=$dir/indiv.lanes
	lhist=$ldir/histos
	fadir=$ldir/fastas
	fqdir=$ldir/fastqs        
	mkdir $ldir $lhist $fadir $fqdir 2>/dev/null


	# check for primers, use corresponding pandaseq command
	# no primers = join only
	# both primers = join AND extract
	# not written for single primers yet, can add later
	if [ -z $fwd ] && [ -z $rev ];
	then
		# NO PRIMERS INCLUDED
		# Join reads
		echo "Joining $lbase reads..."
		pandaseq -f $R1 -r $R2 -F \
		-w $fqdir/$lbase.joined.fastq -t 0.6 -T $threads -l 1 -d rbfkms 2>/dev/null
	else
		# WITH PRIMERS INCLUDED
		# Join reads & extract insert
        	echo "Joining $lbase reads & extracting insert..."
        	pandaseq -f $R1 -r $R2 -F \
        	-p $fwd -q $rev \
        	-w $fqdir/$lbase.joined.fastq -t 0.6 -T $threads -l 1 -d rbfkms 2>/dev/null
	fi
	
	# Convert to fasta	
	echo "Converting joined $lbase FASTQ to FASTA..."
	sed '/^@/!d;s//>/;N' $fqdir/$lbase.joined.fastq > $fadir/$lbase.joined.fasta
	
	# Combine sequences from each lane into single files
	echo "Adding $lbase reads to total $sbase reads..."
	cat $fqdir/$lbase.joined.fastq >> $dir/$sbase.joined.fastq
    cat $fadir/$lbase.joined.fasta >> $dir/$sbase.joined.fasta

	# Generate indiv lane  nt length distributions
	if [ -z $slanes ];
        	then :
		else
		echo "Generating $lbase nt length distribution..."
		readlength.sh in=$fadir/$lbase.joined.fasta out=$lhist/$lbase.joined.nt.histo bin=1 2>/dev/null
		
	fi
done


cd ${outdir}/joined.reads

# loop through directories and generate count files

ls -1 | while read d
do
	test -d "$d" || continue
	echo ""
	echo $d
	# define variables
	base=$(basename ${d})
	(cd $d ;

	# Generate nt length distribution for all lanes combined
	echo "Generating $base nt length distribution..."
	readlength.sh in=$base.joined.fasta out=$base.nt.histo bin=1 2>/dev/null

	# NT SEQ COUNTS
	# convert fasta to tab delimmed file
	# re-write this with gnu
	seqkit fx2tab $base.joined.fasta -o $base.fasta.tab ;

	# extract seqs only, no header
	awk '{print $2}' $base.fasta.tab > $base.seqs.only ;

	# Get unique seq counts (requires fastq seqs ONLY, no fasta headers!)
	sort $base.seqs.only | uniq -c | sort -bgr > $base.nt.counts ;

	# remove temps
	rm $base.seqs.only $base.fasta.tab
	
	# calculate unique and total
	echo "Calculating unique & total reads for $base..."
	unique=$(awk 'END {print NR}' $base.nt.counts)
	total=$(awk '{s+=$1}END{print s}' $base.nt.counts)

	echo "number of unique sequences = $unique" 
	echo "total number of molecules = $total"  
		
	# collect unique, total and sequences with counts in the counts file
	echo "number of unique sequences = $unique" > $outdir/counts/$base\_counts.txt
	echo "total number of molecules = $total"   >> $outdir/counts/$base\_counts.txt
	echo  >>  $outdir/counts/$base\_counts.txt
	awk '{ print $2, $1 }' $base.nt.counts | column -t  >>  $outdir/counts/$base\_counts.txt

	# redirect outputs
	mv $base.joined.fasta $outdir/fastas/$base.joined.fasta
	mv $base.joined.fastq $outdir/fastqs/$base.joined.fastq
	mv $base.nt.histo $outdir/histos/$base.nt.histo
	rm $base.nt.counts
	
        )
done

# cleanup indiv lanes

if [ -z $slanes ];
	then
		echo "Cleaning up $base individual lane outputs..."
                cd $outdir
                rm -r joined.reads/
        else
               	echo "Individual lane outputs will be retained."
fi

#################################




#################################

cd $outdir/counts

for file in *counts.txt

do 
	#LEN HISTOS FOR NT
	#READS
	awk 'NR > 3 {reads+=$2}END{print "#Reads:", reads}' $file > ${file//_counts.txt}'_counts_histo.txt'
	#MIN
	awk 'NR == 4 {line = $0; min = length($1)} NR > 4 && length($1) < min {line = $0; min = length($1)} END{print "Min:", min}' $file >> ${file//_counts.txt}'_counts_histo.txt'
	#MAX
	awk 'NR == 4 {line = $0; max = length($1)} NR > 4 && length($1) > max {line = $0; max = length($1)} END{print "Max:", max}' $file >> ${file//_counts.txt}'_counts_histo.txt'
	#TEST TO PRINT INDIVIDUAL LENGTHS
	#awk 'NR > 3 {print length($1)}' $file  > ${file//_counts.txt}'_counts_histo_test.txt'

	#Read Length Histogram:
	echo "#Read Length Histogram:" >> ${file//_counts.txt}'_counts_histo.txt'
	echo "Len" "Reads" "%Reads" | column -t >> ${file//_counts.txt}'_counts_histo.txt'
	awk 'NR > 3  {reads+=$2; a[length($1)]+=$2}END{for (i in a) printf "%s %s %.5f%% \n",i, a[i], 100*a[i]/reads}' $file | column -t | sort -g -k1  >> ${file//_counts.txt}'_counts_histo.txt'
	
	mv ${file//_counts.txt}'_counts_histo.txt' ../histos/${file//_counts.txt}'_counts_histo.txt'
	
	if [ -z $prot ];
	then
		echo "No translation will be performed"
		
	else
	
	echo $file
	python ../../translate_with_dups.py $file 
	#To print in new file every line except the first 3 (2 with the number of molecules and sequences and town empty lines):
	tail -n +4 ${file//_counts.txt}'_counts_aa_dup.txt' | sort > newfile.txt;
	#To remove duplicates and sum abundances:
	awk '{seen[$1]+=$2}END{for (i in seen) print i, seen[i]}' newfile.txt  |column -t | sort -k1 > newfile2.txt;
	#To sort following abundance:
	sort newfile2.txt -k2 -n -r > newfile3.txt;
	#To print second line:
	val=$(awk 'BEGIN {FS = " "} ; {sum+=$2} END {print sum}' newfile3.txt) ; echo total number of molecules      =     $val | cat - newfile3.txt > newfile4.txt;
	#To print first line:
	val=$(cat newfile3.txt | wc -l) ; echo number of unique sequences     =     $val | cat - newfile4.txt > newfile5.txt;
	#To print third (empty) line:
	awk 'NR==3 {print ""} 1' newfile5.txt > ${file//_counts.txt}'_counts_aa.txt';
	#To remove every temp file:
	rm newfile.txt; rm newfile2.txt; rm newfile3.txt; rm newfile4.txt; rm newfile5.txt
	
	#LEN HISTOS FOR AA
	#READS
	awk 'NR > 3 {reads+=$2}END{print "#Reads:", reads}' ${file//_counts.txt}'_counts_aa.txt' > ${file//_counts.txt}'_counts_aa_histo.txt'
	#MIN
	awk 'NR == 4 {line = $0; min = length($1)} NR > 4 && length($1) < min {line = $0; min = length($1)} END{print "Min:", min}' ${file//_counts.txt}'_counts_aa.txt' >> ${file//_counts.txt}'_counts_aa_histo.txt'
	#MAX
	awk 'NR == 4 {line = $0; max = length($1)} NR > 4 && length($1) > max {line = $0; max = length($1)} END{print "Max:", max}' ${file//_counts.txt}'_counts_aa.txt' >> ${file//_counts.txt}'_counts_aa_histo.txt'
	#TEST TO PRINT INDIVIDUAL LENGTHS
	#awk 'NR > 3 {print length($1)}' ${file//_counts.txt}'_counts_aa.txt' > ${file//_counts.txt}'_counts_aa_histo_test.txt'

	#Read Length Histogram:
	echo "#Read Length Histogram:" >>  ${file//_counts.txt}'_counts_aa_histo.txt'
	echo "Len" "Reads" "%Reads" | column -t >>  ${file//_counts.txt}'_counts_aa_histo.txt'
	awk 'NR > 3  {reads+=$2; a[length($1)]+=$2}END{for (i in a) printf "%s %s %.5f%% \n",i, a[i], 100*a[i]/reads}' ${file//_counts.txt}'_counts_aa.txt' | column -t | sort -g -k1  >>  ${file//_counts.txt}'_counts_aa_histo.txt'

	fi
	
done

cd ..

if [ -z $prot ];
	then
		echo "No translation will be performed"

	else
	
		mkdir counts_aa

		mv counts/*aa.txt counts_aa/
		mv counts/*aa_dup.txt counts_aa/
		mv counts/*aa_histo.txt histos/

fi

#################################################### CREATE LOG FILE FOR NT

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
			$(gzcat $R1 | awk 'END {print NR/4}') \
			$(gzcat $R2 | awk 'END {print NR/4}')  \
			$(cat ${outdir}/counts/$sbase\_counts.txt | awk 'BEGIN {ORS=" "}; NR==1{print $6}' ) \
			$(cat ${outdir}/counts/$sbase\_counts.txt | awk 'BEGIN {ORS=" "}; NR==2{print $6}' ) \
			| column -t >> $outdir/log_temp2.txt
					
		done

		awk '{ printf "%s %.2f%%\n", $0, 100*$5/$2 }' $outdir/log_temp2.txt | column -t >> $outdir/log_temp1.txt



		awk  '{print }' $outdir/log_temp1.txt | column -t > $outdir/log.txt

		rm $outdir/log_temp1.txt
		rm $outdir/log_temp2.txt

	else

#################################################### CREATE LOG FILE FOR NT AND AA

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
			$(gzcat $R1 | awk 'END {print NR/4}') \
			$(gzcat $R2 | awk 'END {print NR/4}')  \
			$(cat ${outdir}/counts/$sbase\_counts.txt | awk 'BEGIN {ORS=" "}; NR==1{print $6}' ) \
			$(cat ${outdir}/counts/$sbase\_counts.txt | awk 'BEGIN {ORS=" "}; NR==2{print $6}' ) \
			$(cat ${outdir}/counts_aa/$sbase\_counts_aa.txt | awk 'BEGIN {ORS=" "}; NR==1{print $6}' ) \
			$(cat ${outdir}/counts_aa/$sbase\_counts_aa.txt | awk 'BEGIN {ORS=" "}; NR==2{print $6}' ) \
			| column -t >> $outdir/log_temp2.txt
					
		done

		#i added this line because I thought it was printing each sample twice, but I don't think it is - I think it was happening when running twice in a row
		#awk '{seenR1[$1]+=$2; seenR2[$1]+=$3; unique[$1]=$4; total[$1]=$5}END{for (i in seenR1) print i, seenR1[i], seenR2[i], unique[i], total[i]}'  $outdir/log_temp2.txt | column -t >> $outdir/log_temp3.txt

		awk '{ printf "%s %s %s %s %s %.2f%% %s %s %.2f%%\n", $1, $2, $3, $4, $5, 100*$5/$2, $6, $7, 100*$7/$2 }' $outdir/log_temp2.txt | column -t >> $outdir/log_temp1.txt

		awk  '{print }' $outdir/log_temp1.txt | column -t > $outdir/log.txt

		rm $outdir/log_temp1.txt
		rm $outdir/log_temp2.txt

fi

cd $outdir/

echo "where now"
echo $(pwd)



python ../log_plot.py log.txt $prot
