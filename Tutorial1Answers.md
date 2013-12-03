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

In order to change the minimum coverage, the __min_coverage__ must be changed within the __mapping.conf__ file.  Please create two new files, mapping.15.conf and mapping.25.conf, change this value, then run the pipeline for each case (note the --output to different directories, and --config to different config files).

	$ snp_phylogenomics_control --mode mapping --input-dir tutorial1_fastq/ --reference reference/08-5578.fasta --output tutorial1_out_15 --config mapping.15.conf
	$ snp_phylogenomics_control --mode mapping --input-dir tutorial1_fastq/ --reference reference/08-5578.fasta --output tutorial1_out_25 --config mapping.25.conf

To look at the differences in the number of SNPs identified, the __scripts/generate_genomes.pl__ command can be used.  Please run as follows:

	$ perl scripts/compare_positions.pl tutorial1_mutations.tsv tutorial1_out_15/pseudoalign/pseudoalign-positions.tsv | column -t
	tutorial1_mutations.tsv  tutorial1_out_15/pseudoalign/pseudoalign-positions.tsv  Intersection  Unique-tutorial1_mutations.tsv  Unique-tutorial1_out_15/pseudoalign/pseudoalign-positions.tsv
	100                      27                                                      27            73                              0
	
	$ perl scripts/compare_positions.pl tutorial1_mutations.tsv tutorial1_out_25/pseudoalign/pseudoalign-positions.tsv | column -t
	tutorial1_mutations.tsv  tutorial1_out_25/pseudoalign/pseudoalign-positions.tsv  Intersection  Unique-tutorial1_mutations.tsv  Unique-tutorial1_out_25/pseudoalign/pseudoalign-positions.tsv
	100                      0                                                       0             100                             0

Compiling these results together results in the above table.

2. All the fastq files we generated were simulated with 100 bp reads.  Adjust the read length using the __--len__ parameter in the __scripts/generate_genomes.pl__ script to 50x and 200x.  What difference does this make to the number of SNPs detected?

From the table below it can be seen that as we increase the read length the number of positions detected increases.  This is most likely due to the ability of longer reads to span more repetitive regions and so unambiguously map to the correct location.

| Read Length | Positions Detected |
| ----------- | ------------------ |
|          50 |                 94 |
|         100 |                 98 |
|         200 |                 99 |

The steps used to generate the above table are given below.

To generate reads at 20x and 200x, we adjust the _--len_ parameter within the __genreate_genomes.pl__ script.  The commands used are (note the different out_dir parameter):

	$ perl scripts/generate_genomes.pl reference/08-5578.fasta tutorial1_mutations.tsv '--len 50 --fcov 30 --noALN --rndSeed 1' tutorial1_fastq_50
	$ perl scripts/generate_genomes.pl reference/08-5578.fasta tutorial1_mutations.tsv '--len 200 --fcov 30 --noALN --rndSeed 1' tutorial1_fastq_200

Now, we run the pipeline (using 5x minimum coverage) for each set of FASTQ files generated above.

	$ snp_phylogenomics_control --mode mapping --input-dir tutorial1_fastq_50/ --reference reference/08-5578.fasta --output tutorial1_out_len_50 --config mapping.conf
	$ snp_phylogenomics_control --mode mapping --input-dir tutorial1_fastq_200/ --reference reference/08-5578.fasta --output tutorial1_out_len_200 --config mapping.conf

Now, we run __scripts/compare_positions.pl__ to compare the positions identified.

	$ perl scripts/compare_positions.pl tutorial1_mutations.tsv tutorial1_out_len_50/pseudoalign/pseudoalign-positions.tsv | column -t
	tutorial1_mutations.tsv  tutorial1_out_len_50/pseudoalign/pseudoalign-positions.tsv  Intersection  Unique-tutorial1_mutations.tsv  Unique-tutorial1_out_len_50/pseudoalign/pseudoalign-positions.tsv
	100                      94                                                          94            6                               0

	$ perl scripts/compare_positions.pl tutorial1_mutations.tsv tutorial1_out_len_200/pseudoalign/pseudoalign-positions.tsv | column -t
	tutorial1_mutations.tsv  tutorial1_out_len_200/pseudoalign/pseudoalign-positions.tsv  Intersection  Unique-tutorial1_mutations.tsv  Unique-tutorial1_out_len_200/pseudoalign/pseudoalign-positions.tsv
	100                      99                                                           99            1                               0
	
Now, compile these results together into the table seen above.
