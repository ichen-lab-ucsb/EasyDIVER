# read-processing-pipeline
This is the README document for the Chen Lab's in-house pipeline for processing HTS reads from selection experiments.

# What exactly does it do?
This pipeline will take raw, paired-end, demultiplexed Illumina read files and:
1. Join them with PANDASeq.
2. Extract the insert sequence based on user-supplied primer sequences.
3. Collect sequence length distributions (histos).
4. Generate counts files for the Chen Lab clustering scripts.
5. Create a log file (v3, v4)
6. Optional translation into amino acids (v4)
7. Create a summary figure of log file (v4)

# Dependencies and Installation
The pipeline script was written to run on Unix-based systems, like Linux, Ubuntu, and MacOS. Windows 10 also has a Linux subsystem and should be able to run the script.

To use the pipeline, first install the two dependencies: python and PANDASeq. We recommend using the Anaconda distribution of python, and adding the Bioconda channel to Anaconda's package manager, conda. We defer to their documentation for installation. After installing Anaconda with Bioconda, PANDASeq is easily installed using conda with:

`conda install pandaseq`

In order for the pipeline to be called reliably, and for the pipeline to call the translator reliably, both scripts must be placed in `/usr/local/bin/` upon download. For example, these files can be placed in that directory with:

`cp /path/to/pipeline.sh /path/to/translator.py /usr/local/bin/` 

The pipeline will not be able to find the translator if it is not stored in `bin/`.

# Input requirements
All inputs must:
1. Be in *one* directory (even reads from separate lanes).
2. Be in FASTQ format.
3. Use the standard Illumina naming scheme: `sample-name_S#_L00#_R#_001.fastq`
4. User either the `.fastq` or `.fastq.gz` extensions.

If any of these requirements are not met, the script will not perform as intended, or more likely, outright fail.
 
# Outputs
If an output directory is not provided using the flag -o, a directory called `pipeline.output` will automatically be created in the same directory as the inputs.  
For each sample, the pipeline will combine the reads from every lane, and redirect the outputs to the following sub-directories:  

`fastqs` will contain the joined fastq files  
`fastas` will contain the joined fasta files  
`counts` will contain all counts files for every sample  
`histos` will contain the nt length distributions  

By default, the script will suppress outputs from individual lanes. If you wish to retain the individual lane outputs, use the `-r` flag. If the flag `-r` is used, files corresponding to the individual lanes (joined fasta files joined fastq files, text counts files and text histograms) are retained and redirected to the subdirectory called `joined.reads`.

Version v3 also prints out a log file with the parameters used and the number of sequences in the fastq and counts files.

Version v4 also allows to translate sequences to amino acids using the genetic code and generates a summary figure based on the log file.

Version v6 allows for: both extraction primers, just one, or none. It also allows the ue of additional PANDASeq internal flags (e.g. L -50). This implies the user can change the values for the couple flagas for which weusing deafult values (-l 1 and -d rbfkms)

# Usage versions v1, v2 and v3
`bash proto.pipeline.vX.sh -i [-o -p -q -r -T -h]`

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
     
# Usage version v4
`bash proto.pipeline.v4.sh -i [-o -p -q -r -T -h -a]`

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
     -a translate to amino acids
     
# Usage version v6
`bash proto.pipeline.v6.sh -i [-o -p -q -r -T -h -a -e]`

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
     -a translate to amino acids
    	-e extra flags for PANDASeq (use quotes, e.g. \"-L 50\")"

     
