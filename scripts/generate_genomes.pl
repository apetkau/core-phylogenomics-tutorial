#!/usr/bin/env perl
# Purpose
# Given a reference FASTA file and a table of variants, generates the corresponding genomes for these variants.

use warnings;
use strict;

use FindBin;
use lib $FindBin::Bin;

use PositionsTable;
use Bio::SeqIO;
use Bio::Seq::SeqFactory;

my $usage =
"$0 [reference.fasta] [variants_table.tsv] [out_dir]\n".
"Parameters:\n".
"\treference.fasta:  A reference genome in FASTA format\n".
"\tvariants_table.tsv:  A tab-deliminited table listing the genomes and variants to insert\n".
"\tout_dir:  The directory to store all output files\n";

# reads all reference sequences into a table structured like
# ref_id => ref_seq
sub read_reference_sequences
{
	my ($reference_file) = @_;
	my %sequence_table;

	my $ref_io = Bio::SeqIO->new(-file=>"< $reference_file",-format=>"fasta");
	die "could not parse reference file $reference_file\n$usage" if (not defined $ref_io);

	while (my $seq = $ref_io->next_seq)
	{
		$sequence_table{$seq->display_id} = $seq;
	}

	return \%sequence_table;
}

############
### MAIN ###
############
die $usage if (@ARGV != 3);
my ($ref_file,$variants_file,$out_dir) = @ARGV;

die "reference.fasta is not defined\n$usage" if (not defined $ref_file);
die "$ref_file does not exist\n$usage" if (not -e $ref_file);
die "variants_table.tsv is not defined\n$usage" if (not defined $variants_file);
die "$variants_file does not exist\n$usage" if (not -e $variants_file);
die "out_dir is not defind\n$usage" if (not defined $out_dir);
die "$out_dir already exists\n$usage" if (-e $out_dir);

my $genomes_out_dir = "$out_dir/genomes";

# read in all positions to mutate
my $variants_parser = PositionsTable->new;
my ($variants_core_table,$variants_core_table_count) = $variants_parser->read_table($variants_file);
my @genome_names = (keys %$variants_core_table);
die "error: no genomes to generate defined in $variants_file" if (@genome_names == 0);

# read original reference sequences
my $reference_table = read_reference_sequences($ref_file);

mkdir $out_dir;
mkdir $genomes_out_dir;

my $factory = Bio::Seq::SeqFactory->new;

# mutate each new genome and write to a file
foreach my $genome_name (@genome_names)
{
	next if ($genome_name eq 'Reference');

	my $genome_file = "$genomes_out_dir/$genome_name.fasta";
	my $variant_entry = $variants_core_table->{$genome_name};
	for my $chrom (keys %$variant_entry)
	{
		my $positions = $variant_entry->{$chrom};
		die "error: no chromsome named $chrom in file $ref_file"
			if (not defined $reference_table->{$chrom});

		my $reference_seq = $reference_table->{$chrom};
		my $seq_string = $reference_seq->seq;

		for my $pos (keys %$positions)
		{
			# insert mutation at position
			my $string_pos = $pos - 1; # position in string starts at 0 not 1
			my $alt = $positions->{$pos}->{'alternative'};
			my $ref = $positions->{$pos}->{'reference'};
			die "error: no alt for $genome_name:$chrom:$pos" if (not defined $alt);
			die "error: invalid alt=$alt for $genome_name:$chrom:$pos" if ($alt !~ /^[ACTG]$/i);
			die "error for $genome_name:$chrom:$pos, position out of bounds in file $ref_file" if ($pos > length($seq_string));

			my $real_ref_base = substr($seq_string,$string_pos,1);
			die "error for $genome_name:$chrom:$pos base($real_ref_base) from file $ref_file != base($ref) from file $variants_file" if (lc($real_ref_base) ne lc($ref));

			substr($seq_string,$string_pos,1) = $alt; # perform mutation
		}

		my $generated_sequence = $factory->create(-seq => $seq_string, -id => $chrom);
		my $seq_writer = Bio::SeqIO->new(-file=>">>$genome_file",-format=>"fasta");
		$seq_writer->write_seq($generated_sequence);
	}
	print "wrote $genome_file\n";
}
print "\n";

# generate reads
