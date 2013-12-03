Tutorial 1 Answers
==================

1. For this tutorial the mean coverage simulated was 30x, and our minimum SNP detection coverage was 5x.  Try changing the minimum coverage to 15x and 25x within the file __mapping.conf__ and re-running the pipeline.  Compare the differences in the number of SNPs detected.  How does the number of SNPs detected change as the minimum coverage increases?

From the table below, it can be observed that as the __min_coverage__ increases, the number of SNPs detected decreases.  This is because the coverage set within the simulations, 30x, is only the mean coverage, which may vary across the genome.

| Coverage | Positions Detected |
| -------- | ------------------ |
|        5 |                 98 |
|       15 |                 27 |
|       25 |                  0 |

The steps used to generate the above table are given below.

In order to change the minimum coverage, the __min_coverage__ must be changed within the __mapping.conf__ file.  Please change this value, then run the pipeline for each case (note the --output to different directories).

	$ snp_phylogenomics_control --mode mapping --input-dir tutorial1_fastq/ --reference reference/08-5578.fasta --output tutorial1_out_15 --config mapping.conf
	$ snp_phylogenomics_control --mode mapping --input-dir tutorial1_fastq/ --reference reference/08-5578.fasta --output tutorial1_out_25 --config mapping.conf

To look at the differences in the number of SNPs identified, the __scripts/generate_genomes.pl__ command can be used.  Please run as follows:

	$ perl scripts/compare_positions.pl tutorial1_mutations.tsv tutorial1_out_15/pseudoalign/pseudoalign-positions.tsv | column -t
	tutorial1_mutations.tsv  tutorial1_out_15/pseudoalign/pseudoalign-positions.tsv  Intersection  Unique-tutorial1_mutations.tsv  Unique-tutorial1_out_15/pseudoalign/pseudoalign-positions.tsv
	100                      27                                                      27            73                              0
	
	$ perl scripts/compare_positions.pl tutorial1_mutations.tsv tutorial1_out_25/pseudoalign/pseudoalign-positions.tsv | column -t
	tutorial1_mutations.tsv  tutorial1_out_25/pseudoalign/pseudoalign-positions.tsv  Intersection  Unique-tutorial1_mutations.tsv  Unique-tutorial1_out_25/pseudoalign/pseudoalign-positions.tsv
	100                      0                                                       0             100                             0

Compiling these results together results in the above table.
