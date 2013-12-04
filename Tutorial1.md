Core Phylogenomics Tutorial 1
=============================

This document walks through how to run the core phylogenomics pipeline and generating a set of SNPs and a phylogenetic tree based on whole genome sequencing data.  This tutorial assumes you have have the pipeline installed and that you have some familiarity with working on the command line in Linux.

Installing Depencencies
-----------------------

This tutorial makes use of the [ART](http://www.niehs.nih.gov/research/resources/software/biostatistics/art/) NGS sequecing read simulator.  This tool (art_illumina) must be installed within your PATH.  To automatically download and build, please use the build_dependencies.sh script and source the file listed on completion of the script.  For example:
	
	$ ./build_dependencies.sh
	...
	**********************
	ART Illumina Installed
	Please run the below command to add to your PATH
	
	source /home/course/aaron/core-phylogenomics-tutorial/software/environment.sh
	**********************

	$ source /home/course/aaron/core-phylogenomics-tutorial/software/environment.sh
	$ art_illumina

This will create a __software/__ directory, build ART within this directory and add __art_illumina__ to your PATH.

Step 1: Obtaining a Reference Genome
------------------------------------

The core phylogenomics pipeline requires a reference genome for reference mapping.  This genome must be in FASTA format.  For the tutorial, the reference genome we will be working with is located in __reference/08-5578.fasta__.  This genome was download from NCBI at http://www.ncbi.nlm.nih.gov/nuccore/NC_013766.1.

	$ ls reference
	08-5578.fasta
	$ head reference/08-5578.fasta
	>gi|284800255|ref|NC_013766.1| Listeria monocytogenes 08-5578 chromosome, complete genome
	TCCACAAGCCATTGTGTGTAATTAACCACTAATTGTGTATAAGTTTAAACTAATTGAAAAGGTTATCCAC
	...

Step 2: Obtaining Sequencing Reads
------------------------------------

The other main data needed for the pipeline is a set of sequencing reads for the other genomes under analysis.  These must be in FASTQ format with file names the same as what will appear in the final phylogenetic tree.

For this tutorial we will be generating the set of genomes by inserting a set of mutations into 08-5578.  We will then simulate NGS sequencing reads on these generated genomes using the __art_illumina__ read simulator.

Inserting a set of mutations and generating sequencing reads can be accomplished with the __scripts/generate_genomes.pl__ script.  The usage for this script is as follows:

	$ perl scripts/generate_genomes.pl
	scripts/generate_genomes.pl [reference.fasta] [variants_table.tsv] [art_illumina_parameters] [out_dir]
	Parameters:
		reference.fasta:  A reference genome in FASTA format
		variants_table.tsv:  A tab-deliminited table listing the genomes and variants to insert
		art_illumina_parameters:  A quoted string containing the art_illumina parameters
		out_dir:  The directory to store all output files

The _reference.fasta_ file has been provided from Step 1.  The _variants_table.tsv_ for this tutorial is named __tutorial1_mutations.tsv__ and includes names of the genomes we will generate and a list of mutations for each genome.  This table looks as follows:

	$ head tutorial1_mutations.tsv
	#Chromosome	Position	Status	Reference	08-5578-0	08-5578-1	08-5578-2	08-5578-3	08-5578-4
	gi|284800255|ref|NC_013766.1|	77005	valid	T	C	T	G	T	C
	gi|284800255|ref|NC_013766.1|	156056	valid	T	C	T	G	T	C
	...

Generating the genomes and sequencing reads we will used for analysis can be accomplished with the following commands:

	$ perl scripts/generate_genomes.pl reference/08-5578.fasta tutorial1_mutations.tsv '--len 100 --fcov 30 --noALN --rndSeed 1' tutorial1_fastq
	Running scripts/generate_genomes.pl with parameters
	reference_file=reference/08-5578.fasta
	...

This will generate a set of genomes within the directory tutorial1_fastq/genomes and a set of sequencing reads within the directory tutorial1_fastq/.  The directory structure looks as follows:

	$ tree tutorial1_fastq/
	tutorial1_fastq/
	├── 08-5578-0.fastq
	├── 08-5578-0.log
	├── 08-5578-1.fastq
	├── 08-5578-1.log
	├── 08-5578-2.fastq
	├── 08-5578-2.log
	├── 08-5578-3.fastq
	├── 08-5578-3.log
	├── 08-5578-4.fastq
	├── 08-5578-4.log
	└── genomes
	    ├── 08-5578-0.fasta
	    ├── 08-5578-1.fasta
	    ├── 08-5578-2.fasta
	    ├── 08-5578-3.fasta
	    └── 08-5578-4.fasta

Each FASTQ file corresponds to a set of 100bp sequencing reads at 30x coverage for one of the generated genomes.  These files look as follows:

	$ head tutorial1_fastq/08-5578-0.fastq
	@gi|284800255|ref|NC_013766.1|-909660
	TGCCACTTATTATGATTCAAGGCGTCGTAGTTACCATTTGGGCAGATATTTATACATTTGGTGGCCGCGGGAATAATTTATCTTTCCTAACCGCAATTTC
	+
	@C@FFFDFHHHH@I#E@JAG?<JCIJIEIHHJEJHJGJDEJJ#JG*?IJD##F#@JJI@FCHEGE#CIIF>ED@D2AFE?;F@DFCCDAD@DCD@#DD#D
	...

Step 3: Running the core SNP pipeline
-------------------------------------

The command __snp_phylogenomics_control__ can used to generate a set of SNPs given the input data genreated above and build a whole genome phylogeny from a multiple alignment of these SNPs.  There are a number of different methods to building a whole genome phylogeny implemented in this pipeline but the method we will focus on for this tutorial is the reference mapping method.  

The reference mapping method can be run using the __--mode mapping__ parameter.  This requires as input the reference FASTA file, the FASTQ sequencing reads and a configuration file defining other parameters for the reference mapping mode.  For this tutorial, the configuration file is named __mapping.conf__ and looks like:

	%YAML 1.1
	---
	min_coverage: 5
	freebayes_params: '--pvar 0 --ploidy 1 --left-align-indels --min-mapping-quality 30 --min-base-quality 30 --min-alternate-fraction 0.75'
	smalt_index: '-k 13 -s 6'
	smalt_map: '-n 24 -f samsoft -r -1 -y 0.5'
	vcf2pseudo_numcpus: 4
	vcf2core_numcpus: 24
	trim_clean_params: '--numcpus 4 --min_quality 20 --bases_to_trim 10 --min_avg_quality 25 --min_length 36 -p 1'
	drmaa_params:
	    general: "-V"
	    vcf2pseudoalign: "-pe smp 4"
	    vcf2core: "-pe smp 24"
	    trimClean: "-pe smp 4"

The main parameter you will want to change here is the __min_coverage__ parameter which defines the minimum coverage in a particular position to be included within the results.  For this tutorial we will leave the minimum coverage at 5 since the mean coverage from our simulated data was 30.  For other data sets with more mean coverage this value could be increased.

In order to run the pipeline, the following command can be used:

	$ snp_phylogenomics_control --mode mapping --input-dir tutorial1_fastq/ --reference reference/08-5578.fasta --output tutorial1_out --config mapping.conf
	
	Running core SNP phylogenomic pipeline on Tue Dec  3 12:18:02 CST 2013
	Core Pipeline git Commit: 3e93c5c1ef436ab6878789d330d343c47562a7a9
	vcf2pseudoalign git Commit: e81ab24e52dc2b8de85c9beed8c2ced8f478d795
	
	Parameters:
	...

When finished, you should expect to see the following output:

	================
	= Output Files =
	================
	tree: /home/course/aaron/core-phylogenomics-tutorial/tutorial1_out/phylogeny/pseudoalign.phy_phyml_tree.txt
	matrix: /home/course/aaron/core-phylogenomics-tutorial/tutorial1_out/pseudoalign/matrix.csv
	pseudoalignment: /home/course/aaron/core-phylogenomics-tutorial/tutorial1_out/pseudoalign/pseudoalign.phy
	stage: mapping-final took 0.00 minutes to complete
	pipeline took 6.18 minutes to complete

The main file you will want to check out include __tutorial1_out/phylogeny/pseudoalign.phy_phyml_tree.txt__, which is the computed phylogenetic tree.  This can be opened up using [FigTree](http://tree.bio.ed.ac.uk/software/figtree/).

Also, the file __tutorial1_out/pseudoalign/matrix.csv__ which contains a matrix of core SNP distances among all the input isolates.

	$ cat tutorial1_out/pseudoalign/matrix.csv
	strain	08-5578	08-5578-0	08-5578-2	08-5578-4	08-5578-1	08-5578-3	
	08-5578	0	98	98	98	0	0	
	08-5578-0	98	0	49	0	98	98	
	08-5578-2	98	49	0	49	98	98	
	08-5578-4	98	0	49	0	98	98	
	08-5578-1	0	98	98	98	0	0	
	08-5578-3	0	98	98	98	0	0	
	

Also, the file __tutorial1_out/pseudoalign/pseudoalign-positions.tsv__ which includes every variant that was used by the pipeline for genetating the phylogenetic tree as well as those that were filtered out.

	$ head tutorial1_out/pseudoalign/pseudoalign-positions.tsv
	#Chromosome	Position	Status	Reference	08-5578-0	08-5578-1	08-5578-2	08-5578-3	08-5578-4
	gi|284800255|ref|NC_013766.1|	77005	valid	T	C	T	G	T	C
	gi|284800255|ref|NC_013766.1|	156056	valid	T	C	T	G	T	C
	gi|284800255|ref|NC_013766.1|	163917	valid	T	C	T	G	T	C
	gi|284800255|ref|NC_013766.1|	177102	valid	A	G	A	T	A	G
	gi|284800255|ref|NC_013766.1|	197161	valid	G	A	G	C	G	A
	gi|284800255|ref|NC_013766.1|	198617	valid	T	C	T	G	T	C
	gi|284800255|ref|NC_013766.1|	222201	valid	A	G	A	T	A	G
	gi|284800255|ref|NC_013766.1|	253430	valid	G	C	G	C	G	C
	gi|284800255|ref|NC_013766.1|	289669	valid	G	C	G	C	G	C
	
This file contains a list of all variants detected by the pipeline, one per line.  Each variant is given a status, with 'valid' indicating that the variants at that position were used for further analysis.

A quick method to count the total number of 'valid' variants used to generate the phylogenetic tree and SNP matrix is with the following command:

	$ grep -c -P "\tvalid\t" tutorial1_out/pseudoalign/pseudoalign-positions.tsv
	98

Since this file is in the exact same format as the variants table used to define the mutations in our simulated data we can check how many of the variants introduced were identified properly by the pipeline.  This can be accomplished with the __diff__ command below:

	$ diff tutorial1_mutations.tsv tutorial1_out/pseudoalign/pseudoalign-positions.tsv
	62d61
	< gi|284800255|ref|NC_013766.1|	1817903	valid	T	G	T	G	T	G
	93d91
	< gi|284800255|ref|NC_013766.1|	2786700	valid	C	T	C	A	C	T

This indicates that the core SNP pipeline is missing two of the variants that were introduced, one at position 1817903 and another at position 2786700.

Alternatively, to get a brief count of the number of differences, you can use the __scripts/compare_positions.pl__ script.

	$ perl scripts/compare_positions.pl tutorial1_mutations.tsv tutorial1_out/pseudoalign/pseudoalign-positions.tsv | column -t
	tutorial1_mutations.tsv  tutorial1_out/pseudoalign/pseudoalign-positions.tsv  Intersection  Unique-tutorial1_mutations.tsv  Unique-tutorial1_out/pseudoalign/pseudoalign-positions.tsv
	100                      98                                                   98            2                               0

This prints the number of positions found within each file, as well as the intersection and unique positions.  This indicates that pipeline is missing 2 of the original set of positions from _tutorial1_mutations.tsv_.  Note: we pipe the output through __column -t__ to line up columns correctly.

Questions
=========

1. The reference mapping alignment BAM files for each genome are located within __tutorial1_out/bam__.  Load one of these files up using software such as [Tablet](http://bioinf.scri.ac.uk/tablet/) and examine the two missing positions 1817903 and 2786700.  What do you notice about these positions?

2. For this tutorial the mean coverage simulated was 30x, and our minimum SNP detection coverage was 5x.  Try changing the minimum coverage to 15x and 25x within the file __mapping.conf__ and re-running the pipeline.  Compare the differences in the number of SNPs detected.  How does the number of SNPs detected change as the minimum coverage increases?

3. All the fastq files we generated were simulated with 100 bp reads.  Adjust the read length using the __--len__ parameter in the __scripts/generate_genomes.pl__ script to 50x and 200x.  What difference does this make to the number of SNPs detected?

[Answers](Tutorial1Answers.md)
