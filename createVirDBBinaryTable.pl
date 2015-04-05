#! /usr/bin/perl
use strict;
use warnings;
use Bio::SearchIO;
use Getopt::Long;
Getopt::Long::Configure('bundling'); # allow 'bundling' options e.g. -alhvax reference: http://search.cpan.org/~jv/Getopt-Long-2.38/lib/Getopt/Long.pm#Bundling
use Text::CSV;

## Program Info:
#
# Name: diversityplot
#
# Function: Parse output from blast of reference strain vs other strains and 
#           creates a diversity plot (stacked histogram) showing if the gene in the reference 
#           strain is present in the other strains.
#
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2010
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# History:
# 7 Jul 2010:           - Coding started
#

my ( $VirDBfasta, $VirDBCSV, $BinaryCSV, $seqName, $append, %fastaHash, @fastaArray );

GetOptions(
	'i|fasta=s' => \$VirDBfasta,
	'c|csv=s' => \$VirDBCSV,
	'o|out=s' => \$BinaryCSV,
	'n|name=s' => \$seqName,
	'append' => \$append
);

sub usage {
	print <<USAGE;
This needs to be done!
USAGE
	exit;
}

fastaToArray();
parseCSV();
binaryCSV();

sub fastaToArray {
	open(FASTA, "<$VirDBfasta") or die("\nError: Cannot open file $VirDBfasta: $!\n");
	while(<FASTA>) {
		chomp;
		if ($_ =~ m/^\>/) { #if the current line starts with the FASTA symbol '>'
			my $gene = substr($_, 1, index($_, " "));
			chop($gene); #remove space at the end
			if (exists $fastaHash{$gene}) {
				print ("\nError $gene already exists.\n");
				exit;
			}
			else {
				push(@fastaArray, $gene);
				$fastaHash{$gene} = 0;
			}
		}
	}
}

sub parseCSV {
	open(CSV, "<$VirDBCSV") or die ("\nError: Cannot open file $VirDBCSV; $!\n");
	my $csv = Text::CSV->new();
	while(<CSV>) {
		if ($csv->parse($_)) {
			my @columns = $csv->fields();
			if ($columns[3]=~/^(\d+\.?\d*|\.\d+)$/ && $columns[3]>=79.9 && $columns[4]>=0.79) { #at least 80% ID and 0.8 length of query used in alignment
				$fastaHash{$columns[1]} = 1	
			}
		}
	} 
	close CSV;
}

sub binaryCSV {
	#if ($append) { #binary CSV already made need to append the new data
	#	open(BINCSV
	#}	
	open(BINCSV, ">$BinaryCSV") or die("$!\n");
	print BINCSV "Gene,$seqName\n";
	foreach (@fastaArray) {
		print BINCSV "$_,".$fastaHash{$_}."\n";
	}	
	close BINCSV;
}
