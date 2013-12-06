Examples
========

Example 1
----------

In this example, I want to go through what happenes when the read coverage for a number of genomes is variable?  What effect does this have on the variants called and those filtered out?

To start, please run the script __scripts/generate_genomes_variable_coverage.pl__ to generate a dataset with variable coverage between 30x and 50x.

	$ perl scripts/generate_genomes_variable_coverage.pl reference/08-5578.fasta tutorial1_mutations.tsv '--len 100 --noALN --rndSeed 2' example1_fastq

This generates a set of fastq reads within the directory example1_fastq.  This directory looks like:

	$ tree example1_fastq/
	example1_fastq/
	├── 08-5578-0.cov-35.log
	├── 08-5578-0.fastq
	├── 08-5578-1.cov-48.log
	├── 08-5578-1.fastq
	├── 08-5578-2.cov-30.log
	├── 08-5578-2.fastq
	├── 08-5578-3.cov-38.log
	├── 08-5578-3.fastq
	├── 08-5578-4.cov-45.log
	├── 08-5578-4.fastq
	└── genomes
	    ├── 08-5578-0.fasta
	    ├── 08-5578-1.fasta
	    ├── 08-5578-2.fasta
	    ├── 08-5578-3.fasta
	    └── 08-5578-4.fasta

The coverage for each of the genomes is stored within the *.log files, so for 08-5578-0.fastq the coverage is 35.

Now we can run the pipeline, setting the minimum coverage to 10.

	$ snp_phylogenomics_control --mode mapping --input-dir example1_fastq/ --reference reference/08-5578.fasta --output example1_out --config mapping.10.conf

Now we can take a look at the how many of the variants we detected.  This is found in the __example1_out/pseudoalign/pseudoalign-positions.tsv__ file, which looks as follows:

	$ head example1_out/pseudoalign/pseudoalign-positions.tsv | column -t
	#Chromosome                    Position  Status  Reference  08-5578-0  08-5578-1  08-5578-2  08-5578-3  08-5578-4
	gi|284800255|ref|NC_013766.1|  77005     valid   T          C          T          G          T          C
	gi|284800255|ref|NC_013766.1|  156056    valid   T          C          T          G          T          C
	gi|284800255|ref|NC_013766.1|  163917    valid   T          C          T          G          T          C
	gi|284800255|ref|NC_013766.1|  177102    valid   A          G          A          T          A          G
	gi|284800255|ref|NC_013766.1|  197161    valid   G          A          G          C          G          A
	gi|284800255|ref|NC_013766.1|  198617    valid   T          C          T          G          T          C
	gi|284800255|ref|NC_013766.1|  222201    valid   A          G          A          T          A          G
	gi|284800255|ref|NC_013766.1|  253430    valid   G          C          G          C          G          C
	gi|284800255|ref|NC_013766.1|  289669    valid   G          C          G          C          G          C

The status column indicates whether or not a particular position containing variants is kept for further analysis, or filtered out.  A status of 'valid' indicates that all the variants (or non-variants) at this position passed our cutoff criteria.  There are 3 other possible status codes, _filtered-coverage_, _filtered-mpileup_, and _filtered-invalid_.  Let's search for any positions that are not valid.

	$ grep -Pv '\tvalid\t' example1_out/pseudoalign/pseudoalign-positions.tsv | column -t
	#Chromosome                    Position  Status            Reference  08-5578-0  08-5578-1  08-5578-2  08-5578-3  08-5578-4
	gi|284800255|ref|NC_013766.1|  310291    filtered-mpileup  A          G          A          N          A          G
	gi|284800255|ref|NC_013766.1|  1160043   filtered-mpileup  A          N          A          N          A          T
	gi|284800255|ref|NC_013766.1|  1317004   filtered-mpileup  A          T          A          N          A          T
	gi|284800255|ref|NC_013766.1|  1568733   filtered-mpileup  C          A          C          N          C          A
	gi|284800255|ref|NC_013766.1|  1599717   filtered-mpileup  T          N          T          N          T          C
	gi|284800255|ref|NC_013766.1|  1764466   filtered-mpileup  A          T          A          N          A          T
	gi|284800255|ref|NC_013766.1|  1766678   filtered-mpileup  C          N          C          N          C          A
	gi|284800255|ref|NC_013766.1|  1983855   filtered-mpileup  C          N          C          N          C          A
	gi|284800255|ref|NC_013766.1|  2114567   filtered-mpileup  A          T          A          N          A          T
	gi|284800255|ref|NC_013766.1|  2594300   filtered-mpileup  T          N          T          N          T          G
	gi|284800255|ref|NC_013766.1|  2833134   filtered-mpileup  A          N          A          N          A          G

All of these positions have a status of 'filtered-mpileup'.  This status code indicates that there was an inconsistency between a variant call from [samtools mpileup | bcftools](http://samtools.sourceforge.net/mpileup.shtml) and [freebayes](https://github.com/ekg/freebayes), the two variant callers used within this pipeline.  The inconsistent base calls are indicated with an 'N' character.

In order to take a deeper look at what is going on, let us consider the position 310291.  An 'N' character shows up for genome __08-5578-2__.  The variant calls for this genome are stored within two separate files, __example1_out/mpileup/08-5578-2.vcf.gz__ for the 'samtools mpileup' variant calls and __example1_out/vcf-split/08-5578-2.vcf.gz__ for the 'freebayes' variant calls.

For samtools mpileup variant calls we find:

	$ zgrep -P '\t310291\t' example1_out/mpileup/08-5578-2.vcf.gz
	gi|284800255|ref|NC_013766.1|   310291  .       A       T       222     .       DP=17;VDB=0.0333;AF1=1;AC1=2;DP4=1,2,4,10;MQ=59;FQ=-50;PV4=1,1,1,0.16   GT:PL:GQ        1/1:255,23,0:43

This indicates that 'samtools mpileup' found a variant A -> T with a total depth of coverage (DP) of 17.

For freebayes variant calls we find: 

	$ zgrep -P '\t310291\t' example1_out/vcf-split/08-5578-2.vcf.gz
	
This indicates there was no variant call from freebayes given our initial cutoff criteria.  Because these two variant calls are inconsistent, the position 310291 for genome 08-5578-2 is marked with an 'N'.  Because not every variant call for position 310291 meets our cutoff criteria, then this entire position is excluded from further analysis.

A similar situation exists for the positions indicated above.

In order to see the total number of positions actually included in our analysis compared to the expected number, the following command can be used.

	$ perl scripts/compare_positions.pl tutorial1_mutations.tsv example1_out/pseudoalign/pseudoalign-positions.tsv  | column -t
	tutorial1_mutations.tsv  example1_out/pseudoalign/pseudoalign-positions.tsv  Intersection  Unique-tutorial1_mutations.tsv  Unique-example1_out/pseudoalign/pseudoalign-positions.tsv
	100                      87                                                  87            13                              0
	
This indicates that out of all 100 mutations introduced, only 87 were detected.  The 13 remaining positions include both those positions with a status of 'filtered-mpileup' and a few positions not detected at all.
