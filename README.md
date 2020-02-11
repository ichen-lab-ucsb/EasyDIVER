![EasyDIVER Logo](logo.png)


# EasyDIVER
This is the README document for the EasyDIVERS pipeline for pre-processing HTS reads from _in vitro_ selection experiments. The pipeline can be used to process nucleotides or amino acids sequencing data.

# Dependencies and Installation
The pipeline script was written to run on Unix-based systems, like Linux, Ubuntu, and MacOS. Windows 10 also has a [Linux subsystem](https://docs.microsoft.com/en-us/windows/wsl/faq).

To use the pipeline, first install the two dependencies: [Python](https://www.python.org/downloads/) and [PANDASeq](https://github.com/neufeld/pandaseq/wiki/Installation). We recommend using the Anaconda distribution of python, and adding the Bioconda channel to Anaconda's package manager, conda. See the [Anaconda documentation](https://docs.anaconda.com/anaconda/install/) for installation. After installing Anaconda with [Bioconda](https://bioconda.github.io/), PANDASeq is easily installed using conda with:

`conda install pandaseq`

In order for the pipeline to be called from any directory and for the pipeline to call the translator reliably, both scripts must be placed in `/usr/local/bin/` upon download. For example, these files can be placed in that directory with:

`cp /path/to/pipeline.sh /path/to/translator.py /usr/local/bin/` 

To install EasyDIVER, execute from the local directory where it's stored (the first command makes it executable, the second comman installs EasyDIVER):

`chmod +x easydiver.sh`

`sudo install easydiver.sh`

The pipeline will not be found unless it is stored in the working directory or in `bin/`. Also, the pipeline will not be able to find the translator if it is not stored in `bin/`. If EasyDIVER is not installed, then the command bash and the full script name (easydiver.sh) must be used to run the pipeline (e.g. `bash easydiver.sh -i [-o -p -q -h -a -r -T -e]`). 

# Usage

Please consult the EasyDIVER [manual](https://github.com/ichen-lab-ucsb/EasyDIVER/blob/master/MANUAL.pdf). 
`easydiver -i [-o -p -q -h -a -r -T -e]`

# Test dataset

A test dataset is provided. The test data corresponds to two samples obtained from a real experiment of in vitro evolution of mRNA displayed peptides. 
     
# Reporting bugs

Please report any bugs to Celia Blanco (blanco@ucsb.edu) or Sam Verbanic (sverbanic@ucsb.edu). 

When reporting bugs, please include the full output printed in the terminal when running the pipeline. 

# Citation

Celia Blanco<sup>\*</sup>, Samuel Verbanic<sup>\*</sup>, Burckhard Seelig and Irene A. Chen. EasyDIVER: a pipeline for assembling and counting high throughput sequencing data from in vitro evolution of nucleic acids or peptides. *Submitted.*

