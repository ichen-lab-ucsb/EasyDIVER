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

usage="USAGE: bash proto.pipeline.v2.sh -i [-o -p -q -r -T -h]
where:
	REQUIRED
        -i input directory filepath
        
	OPTIONAL
	-o output directory filepath
        -p forward primer sequence for extraction
        -q reverse primer sequence for extraction
	-r retain individual lane outputs
	-T # of threads
	-h prints this friendly message"

# set home directory
hdir=$(pwd)

# parse arguments and set global variables
while getopts hi:o:p:q:T:r option
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

esac
done

# argument report
# check arguments, print, exit if necessary w/ message
if [ -z $helpm ];
	then
		printf "%`tput cols`s"|tr ' ' '#'
		echo "-----Welcome to the Unnamed Chen Lab Pipeline!-----"
		echo "--------You passed the following arguemnts---------"
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
fi

if [ -z $fwd ];
        then
                echo "-----WARNING: No forward primer supplied - extraction will be skipped."
	else
		echo "-----Forward Primer: $fwd"
fi

if [ -z $rev ];
        then
                echo "-----WARNING: No reverse primer supplied - extraction will be skipped."
	else
		echo "-----Reverse Primer: $rev"
fi

if [ -z $slanes ];
        then
                echo "-----Individual lane outputs will be suppressed."
        else
                echo "-----Individual lane outputs will be retained."
fi

if [ -z $threads ];
	then
		echo "-----# of threads undefined; proceeding with 1 thread, this could take a while..."
		threads=1
	else
		echo "-----# of threads = $threads"
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
	echo "number of unique sequences = $unique" >> $outdir/counts/$base\_counts.txt
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



