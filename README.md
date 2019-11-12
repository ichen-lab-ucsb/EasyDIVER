# read-processing-pipeline
# This is the README document for the Chen Lab's in-house pipeline for processing HTS reads from selection experiments

# This pipeline will take paired-end, demultiplexed Illumina read files and:
#	1. Join them with PANDASeq.
#	2. Extract the insert sequence based on user-supplied primer sequences.
#	3. Collect sequence length distributions (histos)
#	4. Generate counts files for the Chen Lab clustering scripts.

# INPUT REQUIREMENTS
# All inputs must:
#	1. Be in the same directory (even reads from separate lanes).
#	2. Be in FASTQ format.
#	3. Use the standard Illumina naming scheme: sample-name_S#_L00#_R#_001.fastq
#	4. User either the .fastq or .fastq.gz extensions.
# If any of these requirements are not met, the script will not perform as intended, or more likely, outright fail.
# 
# OUTPUTS
# If an output directory is not provided to the script, it will automatically make one
# in the same directory where the script was called.
# By default, the script will suppress outputs from individual lanes.
# Instead, it will combine the reads from each lane, for each sample,
# and redirect the outputs to the following sub-directories:
# 'fastqs' will contain the joined fastq files
# 'fastas' will contain the joined fasta files
# 'counts' will contain all counts files for every sample
# 'histos' will contain the nt length distributions
# If you wish to retain the individual lane outputs, use the -r flag

# USAGE
# bash proto.pipeline.v2.sh -i [-o -p -q -r -T -h]
# where:
#        REQUIRED
#        -i input directory filepath
#        
#        OPTIONAL
#        -o output directory filepath
#        -p forward primer sequence for extraction
#        -q reverse primer sequence for extraction
#        -r retain individual lane outputs
#        -T # of threads
#        -h prints this friendly message

