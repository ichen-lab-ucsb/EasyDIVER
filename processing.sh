#!/bin/bash

# This is a pipeline for joining sequence reads and extracting primers

# by Sam Verbanic and Celia Blanco
# contact: samuel.verbanic@lifesci.ucsb.edu or cblanco@chem.ucsb.edu
# Dependencies:
	# bioconda
	# pandaseq
	# libtool
	# bzip2
	# fq2fa
	# seqkit
	# bbmap


for R1 in *_R1_*
do
	
	# Set working directory
	
	cd
	cd Desktop/testing
	mkdir counts
	cd raw.reads

	# Define some general use variables
	
	basename=$(basename ${R1})
	base=${basename//_R*}
	base2=${basename//_L00*}
	R2=${R1//R1_001.fastq.gz/R2_001.fastq.gz}
	
	# Join & extract lane 1 - CHANGE PRIMERS ACCORDING TO PROJECT

	echo "Joining $base lane 1..."
	
	echo "Joining $base lane 1..."
	pandaseq -f $R1 -r $R2 -F \
	-p CTACGAATTC -q CTGCAGTGAA \
	-w $base.joined.fastq -t 0.6 -T 14 -l 1 -C completely_miss_the_point:0

	# Convert to fasta

	fq2fa $base.joined.fastq $base.joined.fasta

	# make directory for analyses
	
	dump=joined.files
	dir=$dump/$base2
	mkdir $dump $dir
	
	# Move input files to new directory
	
	mv $base.joined.fastq $dir/$base.joined.fastq
	mv $base.joined.fasta $dir/$base.joined.fasta
	#mv $base.trimmed.fasta $dir/$base.trimmed.fasta

	# Generate nt length distributions
	
	echo "Generating $base nt length distribution..."
	readlength.sh in=$dir/$base.joined.fasta out=$dir/$base.joined.nt.histo bin=1
	
	cd $dir
	
	# Combine sequences from each lane into single files
	
	cat $base.joined.fastq >> $base2.joined.fastq
	cat $base.joined.fasta >> $base2.joined.fasta

done

cd ../

# loop through directories and generate count files

ls -1 | while read d
do
        test -d "$d" || continue
        echo $d
        # define variables
        base=$(basename ${d})
        (cd $d ; echo "In ${PWD}" ;

        # begin with nt seqs
        # convert fasta to tab delimmed file

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
		
		echo "number of unique sequences = $unique" >> ../../../counts/$base\_counts.txt
		echo "total number of molecules = $total"   >> ../../../counts/$base\_counts.txt
		echo  >>  ../../../counts/$base\_counts.txt
		awk '{ print $2, $1 }' $base.nt.counts | column -t  >>  ../../../counts/$base\_counts.txt

        )
done

