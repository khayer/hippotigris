hippotigris
===========

A collection used for the SRA normalization scripts.

### Sampling fastq files

    Usage: sample_fastq.rb [options] fwd.fq[.gz] rev.fq[.gz] out_prefix

    Samples N=1Mio reads from paired end fastq files.

        -n, --number [NUMBER]            How many reads to sample?, Default: 1Mio
        -r, --randomize_n [NUMBER]       Give range to randomize N, example: '10,20'
        -v, --verbose                    Run verbosely
        -V, --version                    Print version
        -d, --debug                      Run in debug mode


### Trimming fastq files

    Usage: trimmer.rb [options] in.fq[.gz] out.fq

    Trim all reads to 75 bases

        -n, --number [NUMBER]            How many bases to trim?, Default: 75 bases
        -v, --verbose                    Run verbosely
        -V, --version                    Print version
        -d, --debug                      Run in debug mode
