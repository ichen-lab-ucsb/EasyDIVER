![EasyDIVER Logo](logo.png)


# EasyDIVER
This is the README document for the EasyDIVERS pipeline for pre-processing HTS reads from _in vitro_ selection experiments. The pipeline can be used to process nucleotides or amino acids sequencing data.

# Usage

Please consult the EasyDIVER [manual](https://github.com/ichen-lab-ucsb/EasyDIVER/blob/master/MANUAL.pdf). 
`easydiver -i [-o -p -q -T -a -r -e -h]`


| Flag | Description                                 | Comments                                                                                                |
|------|---------------------------------------------|---------------------------------------------------------------------------------------------------------|
| -i   | Input   directory path and name             | Required                                                                                                |
| -o   | Output   directory path and name            | Optional       Default   value: /pipeline.output                                                        |
| -p   | Extraction   forward DNA primer             | Optional                                                                                                |
| -q   | Extraction   reverse DNA primer             | Optional                                                                                                |
| -T   | Number   of threads used for computation    | Optional    Default   value: 1                                                                          |
| -a   | Translation   into amino acids is performed | Optional    Default   value: FALSE                                                                      |
| -r   | Files   for individual lanes are retained   | Optional    Default   value: FALSE                                                                      |
| -e   | Additional   internal PANDAseq flags        | Optional    Must   be entered in quotation marks (e.g. -e “-L 50”)    Default   value: “-l 1 -d rbfkms“ |
| -h   | Help   message                              | Optional                                                                                                |


# Dependencies
The pipeline script was written to run on Unix-based systems, like Linux, Ubuntu, and MacOS. Windows 10 also has a [Linux subsystem](https://docs.microsoft.com/en-us/windows/wsl/faq).

To use the pipeline, first install the two dependencies: [Python](https://www.python.org/downloads/) and [PANDASeq](https://github.com/neufeld/pandaseq/wiki/Installation). We recommend using the Anaconda distribution of python, and adding the Bioconda channel to Anaconda's package manager, conda. See the [Anaconda documentation](https://docs.anaconda.com/anaconda/install/) for installation. After installing Anaconda with [Bioconda](https://bioconda.github.io/), PANDASeq is easily installed using conda with:

`conda install pandaseq`

In order for the pipeline to be called from any directory and for the pipeline to call the translator reliably, both scripts must be placed in a directory that is in the user's PATH environment variable upon download. For example, for Unix/Linux users, scripts could be placed in `/usr/local/bin/` upon download. These files can be placed in that directory with the command:

`cp /path/to/pipeline.sh /path/to/translator.py /usr/local/bin/` 

EasyDIVER and the translation tool must be made executable. This can be done by entering the following commands from the local directory where they are stored:

`chmod +x easydiver.sh`
`chmod +x translator.py`

The pipeline will not be found unless it is stored in the working directory or in a directory that is in the user's PATH environment (e.g. `bin/`). Also, the pipeline will not be able to find the translator if it is not stored in a directory that is in the user's PATH environment (e.g. `bin/`). 

# INPUT

All input files must be:
    
1. Located in the same directory (even reads from separate lanes).
2. In FASTQ format
3. Named using the standard Illumina naming scheme: sample-name_S#_L00#_R#_001.fastq
4. In either .fastq or .fastq.gz extensions.

# Test dataset

A test dataset is provided. The test data corresponds to two samples obtained from a real experiment of in vitro evolution of mRNA displayed peptides. 
     
# Reporting bugs

Please report any bugs to Celia Blanco (celiablanco@ucla.edu). 

When reporting bugs, please include the full output printed in the terminal when running the pipeline. 
If a problem is encountered using a newer MacOS, you may try the following:
1. Install Homebrew (see here: https://brew.sh/)
2. brew install libtool

# Citation

Celia Blanco<sup>\*</sup>, Samuel Verbanic<sup>\*</sup>, Burckhard Seelig and Irene A. Chen. [EasyDIVER: a pipeline for assembling and counting high throughput sequencing data from in vitro evolution of nucleic acids or peptides.](https://link.springer.com/article/10.1007/s00239-020-09954-0) J Mol Evol 88, 477–481 (2020).

