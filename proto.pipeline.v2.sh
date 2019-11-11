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

usage="USAGE: bash proto.pipeline.v2.sh -i [-o -p -q -t -h]
where:
        -i input directory filepath
        -o output directory filepath
        -p forward primer sequence for extraction
        -q reverse primer sequence for extraction
	-t # of threads
	-h prints this friendly message"

# set home directory
hdir=$(pwd)

# parse arguments and set global variables
while getopts :i:o:p:q:t:h option
do
case "${option}"
in

h) 	printf "%`tput cols`s"|tr ' ' '#'
	echo "$usage"
	printf "%`tput cols`s"|tr ' ' '#'
	exit 1;;
i) inopt=${OPTARG};;
o) outopt=${OPTARG};;
p) fwd=${OPTARG};;
q) rev=${OPTARG};;
t) threads=${OPTARG};;
esac
done

# argument report
# check arguments, print, exit if necessary w/ message


if [ -z $helpm ];
	then
		echo "Parsing arguments now. Welcome to the pipeline!"
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
                mkdir $inopt
                cd $inopt
                fastqs=$(pwd)
                echo "Input directory path: $fastqs"
fi

if [ -z "$outopt" ];
        then
                outdir=$hdir/pipeline.output
                echo "No output directory supplied. New output directory is: $outdir"
        else
                # define output variable with correct path name
                mkdir $outopt
                cd $outopt
                outdir=$(pwd)
                echo "Output directory path: $outdir"
fi

if [ -z $fwd ];
        then
                echo "WARNING: No forward primer supplied - extraction will be skipped."
fi

if [ -z $rev ];
        then
                echo "WARNING: No reverse primer supplied - extraction will be skipped."
fi

if [ -z $threads ];
	then
		echo "# of threads undefined; proceeding with 1 thread, this could take a while..."
		threads=1
	else
		echo "# of threads = $threads"
fi


# move to working directory
# make output directories
cd $outdir
mkdir counts joined.reads

# loop through reads
# begin processing
for R1 in $fastqs/*R1*
do
	# Define some general use variables
	## these will always be set for standard Illumina naming schemes
	## it will pretty much break if anything else is used.
	## we can think about making a sloppy alternative for whatever weird names people choose.
	basename=$(basename ${R1})
	base=${basename//_R*}
	base2=${basename//_L00*}
	R2=${R1//R1_001.fastq./R2_001.fastq.}
	
	# make directory for analyses
        ## was dump
        dir=$outdir/joined.reads/$base2
        mkdir $dir
	cd $dir

	# check for primers, use corresponding pandaseq command
	# no primers = join only
	# both primers = join AND extract
	# not written for single primers yet, can add later
	if [ -z $fwd ] && [ -z $rev ];
	then
		# NO PRIMERS INCLUDED
		# Join reads
		echo "Joining $base reads..."
		pandaseq -f $R1 -r $R2 -F \
		-w $base.joined.fastq -t 0.6 -T $threads -l 1 -d rbfkms
	else
		# WITH PRIMERS INCLUDED
		# Join reads & extract insert
        	echo "Joining $base reads & extracting insert..."
        	pandaseq -f $R1 -r $R2 -F \
        	-p $fwd -q $rev \
        	-w $base.joined.fastq -t 0.6 -T $threads -l 1 -d rbfkms
	fi
	
	# Convert to fasta	
	sed '/^@/!d;s//>/;N' $base.joined.fastq > $base.joined.fasta
	
	
	# Separate joined reads by format
	## also an argument??
	
	mv $base.joined.fastq $dir/$base.joined.fastq
	mv $base.joined.fasta $dir/$base.joined.fasta
	#mv $base.trimmed.fasta $dir/$base.trimmed.fasta

	 # Combine sequences from each lane into single files
        cat $base.joined.fastq >> $base2.joined.fastq
        cat $base.joined.fasta >> $base2.joined.fasta

	# Generate nt length distributions
	
	echo "Generating $base nt length distribution..."
	readlength.sh in=$dir/$base.joined.fasta out=$dir/$base.joined.nt.histo bin=1
	
done


cd ${outdir}/joined.reads

# loop through directories and generate count files
## can we do this more elegantly??

ls -1 | while read d
do
        test -d "$d" || continue
        echo $d
        # define variables
        base=$(basename ${d})
        (cd $d ; echo "In ${PWD}" ;

        # begin with nt seqs
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
		unique=$(awk 'END {print NR}' $base.nt.counts)
		total=$(awk '{s+=$1}END{print s}' $base.nt.counts)

		echo "number of unique sequences = $unique" 
		echo "total number of molecules = $total"  
		
		# print unique, total and sequences with counts in the counts file
		echo "number of unique sequences = $unique" >> $outdir/counts/$base\_counts.txt
		echo "total number of molecules = $total"   >> $outdir/counts/$base\_counts.txt
		echo  >>  $outdir/counts/$base\_counts.txt
		awk '{ print $2, $1 }' $base.nt.counts | column -t  >>  $outdir/counts/$base\_counts.txt

        )
done

