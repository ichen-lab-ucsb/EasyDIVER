![EasyDIVER Logo](logo.png)


# EasyDIVER
This is the README document for the EasyDIVERS pipeline for pre-processing HTS reads from _in vitro_ selection experiments. The pipeline can be used to process nucleotides or amino acids sequencing data.

# Usage
`easydiver -i [-o -p -q -r -T -h -a -e]`

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
 
The flag `-e` allows the use of additional PANDASeq internal flags (e.g. L -50). Unless otherwise specified, the pipeline uses by default the internal PANDASeq flags and values `-l 1` and `-d rbfkms`. These can be changed using the flag `-e`.

# What exactly does it do?
This pipeline takes raw, paired-end, demultiplexed Illumina read files and:
1. Joins them with [PANDASeq](https://storage.googleapis.com/pandaseq/pandaseq.html).
2. Extracts the insert sequence based on (optionally) user-supplied primer sequences.
3. Optionally translates into amino acids.
4. Generates counts files.
5. Collects sequence length distributions (histos).
6. Creates a log file.

# Dependencies and Installation
The pipeline script was written to run on Unix-based systems, like Linux, Ubuntu, and MacOS. Windows 10 also has a [Linux subsystem](https://docs.microsoft.com/en-us/windows/wsl/faq).

To use the pipeline, first install the two dependencies: [Python](https://www.python.org/downloads/) and [PANDASeq](https://github.com/neufeld/pandaseq/wiki/Installation). We recommend using the Anaconda distribution of python, and adding the Bioconda channel to Anaconda's package manager, conda. See the [Anaconda documentation](https://docs.anaconda.com/anaconda/install/) for installation. After installing Anaconda with [Bioconda](https://bioconda.github.io/), PANDASeq is easily installed using conda with:

`conda install pandaseq`

In order for the pipeline to be called from any directory and for the pipeline to call the translator reliably, both scripts must be placed in `/usr/local/bin/` upon download. For example, these files can be placed in that directory with:

`cp /path/to/pipeline.sh /path/to/translator.py /usr/local/bin/` 

To install EasyDIVER, execute from the local directory where it's stored (the first command makes it executable, the second comman installs EasyDIVER):

`chmod +x easydiver.sh`

`sudo install easydiver.sh`

The pipeline will not be found unless it is stored in the working directory or in `bin/`. Also, the pipeline will not be able to find the translator if it is not stored in `bin/`. If EasyDIVER is not installed, then the command bash and the full script name (easydiver.sh) must be used to run the pipeline (e.g. `bash easydiver.sh -i [-o -p -q -r -T -h -a -e]`). 

# Input requirements
All input files must:
1. Be in *one* directory (even reads from separate lanes).
2. Be in FASTQ format.
3. Use the standard Illumina naming scheme: `sample-name_S#_L00#_R#_001.fastq`
4. User either the `.fastq` or `.fastq.gz` extensions.

If any of these requirements are not met, the script will not perform as intended, or more likely, outright fail.
 
# Output files
All output files are redirected to the output directoy name and location provided by the flag `-o`. If an output directory is not provided, a default output directory called `pipeline.output` is automatically created in the same directory as the inputs.  
For each sample, the pipeline combines the reads from every lane, and redirects the outputs to the following sub-directories:  
`fastqs` will contain the joined fastq files  
`fastas` will contain the joined fasta files  
`counts` will contain all counts files for every sample  
`histos` will contain the nt length distributions  

By default, the script will suppress outputs from individual lanes. If you wish to retain the individual lane outputs, use the `-r` flag. If the flag `-r` is used, files corresponding to the individual lanes (joined fasta files joined fastq files, text counts files and text histograms) are retained and redirected to the subdirectory called `individual.lanes`.

If translation to amino acids is derided (indicated by the use of the flag `-a`) the counts files are translated using the standard genetic code, and count files and length distributions are created for the amino acid sequences as well. 

For the record, and to monitor the sucess of the run, a single log text file with the parameters used and the number of sequences in the fastq and counts files is created at the end of the process.

 
# Test dataset

A test dataset is provided. The test data corresponds to two samples obtained from a real experiment of in vitro evolution of mRNA displayed peptides. 
     
