hippotigris
===========

A collection used for the SRA normalization scripts.

### Sampling fastq files

    Usage: sample_fastq.rb [options] fwd.fq[.gz] rev.fq[.gz] out_prefix

    Samples N=1Mio reads from paired end fastq files.

        -n, --number [NUMBER]            How many reads to sample?, Default: 1Mio
        -r, --randomize_n [NUMBER]       Give range to randomize N, example: '10,20'
        -v, --[no-]verbose               Run verbosely
        -d, --debug                      Run in debug mode


