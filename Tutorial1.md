Core Phylogenomics Tutorial 1
=============================

This document walks through how to run the core phylogenomics pipeline.  This tutorial assumes you have have the pipeline installed and that you have some familiarity with working on the command line in Linux.

Installing Depencencies
-----------------------

This tutorial makes use of the [ART](http://www.niehs.nih.gov/research/resources/software/biostatistics/art/) NGS sequecing read simulator.  This tool (art_illumina) must be installed within your PATH.  To automatically download and build, please use the build_dependencies.sh script and source the file listed on completion of the script.  For example:
	
	./build_dependencies.sh
	source /home/aaron/Projects/software/core-phylogenomics-tutorial/software/environment.sh
	art_illumina

This will create a __software/__ directory and build ART within this directory.

Step 1: Obtaining a Reference Genome
------------------------------------

The core phylogenomics pipeline requires a reference genome to perform reference mapping against.  This genome must be in FASTA format.  For the tutorial, the reference genome we will be working with is located in __reference/08-5578.fasta__.  This genome was download from NCBI at http://www.ncbi.nlm.nih.gov/nuccore/NC_013766.1.

	$ ls reference
	08-5578.fasta
	$ head reference/08-5578.fasta
	>gi|284800255|ref|NC_013766.1| Listeria monocytogenes 08-5578 chromosome, complete genome
	TCCACAAGCCATTGTGTGTAATTAACCACTAATTGTGTATAAGTTTAAACTAATTGAAAAGGTTATCCAC
	...

Step 2: Obtaining Sequencing Reads
------------------------------------

The other main data needed for the pipeline is a set of sequencing reads for the other genomes under analysis.  These must be in FASTQ format with file names the same as what will appear in the final phylogenetic tree.  For this tutorial we will be generating the set of genomes by inserting a set of mutations into 08-5578.  We will then simulate NGS sequencing reads on these generated genomes using the __art_illumina__ read simulator.

