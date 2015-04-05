#! /usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;
use Bio::SeqIO;
use Bio::Perl;

## Program Info:
#
# Name: extractUpStreamDNA.pl
#
# Function: Takes a Genbank file as input. Parses through and for every CDS that it finds, it extracts a pre-determined length of DNA upstream (length will be an argument) 
# 	    The sequence length will be the argument length + 3 as the initiation codon will be included.
#	    Output will be an FFN file of these upstream DNA sequences. This only WORKS for prokaryotic sequences because it does not handle Splits or Joins found in eukaryotic.#	     NOTE: Please make sure that the 'locus_tag' sub-feature is found under the 'CDS' main feature
#	    NOTE: The coordinates given in the fasta line in the FFN file are the coordinates of the extracted region.
#	    NOTE: This currently only works for linearized genomes. In the case of a circular genome, there may be no upstream regions when the gene starts at the origin.
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2011
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# History:
# 14 March 2011		- finished initial version
# 16 March 2011		- modified script to include initiation codon and to use locus_tag as the identifier name in the fasta line
#
my ( $gbkfile, $ffnfile, $length );

GetOptions(
	'i|input=s' => \$gbkfile,
	'o|output=s' => \$ffnfile,
	'l|length=s' => \$length
);

usage() unless $gbkfile && $ffnfile && $length;

sub usage {
	print <<USAGE;
extractUpStreamDNA.pl	Takes a Genbank file as input. Parses through and for every CDS that it finds, 
			it extracts a pre-determined length of DNA upstream (length will be an argument). 
  			The sequence length will be the argument length + 3 as the initiation codon will be included.
			Output will be an FFN file of these upstream DNA sequences. 
			This only WORKS for prokaryotic sequences because it does not handle Splits or Joins found in eukaryotic.
			NOTE: Please make sure that the 'locus_tag' sub-feature is found under the 'CDS' main feature
			NOTE: The coordinates given in the fasta line in the FFN file are the coordinates of the extracted region.
			NOTE: This currently only works for linearized genomes. In the case of a circular genome, there may be no upstream regions when the gene starts at the origin.

Usage:	[option]
	-i | --input	Path to input Genbank file
	-o | --output	Path to output FFN file
	-l | --length   Length of upstream sequence to extract (bases)

Explanation:
e.g. if length = 5 and sequence = 'bioinformatics' and we want to return the sequence of length 5 upstream from 't', it will return 'formatic'.
	NOTE: 'tic' is included because the initiation codon is included in the returned sequence.

Example:
perl extractUpStreamDNA.pl -i inputfile -o outputfile -l 35

USAGE
	exit;
}

extractUpStreamDNA();

exit;

sub extractUpStreamDNA {
	my $gbk = Bio::SeqIO->new(-file => $gbkfile, -format => 'genbank');
	my $seq = $gbk->next_seq;
	my @cds = grep { $_->primary_tag eq 'CDS' } $seq->get_SeqFeatures;
	
	open(OUTPUT, ">$ffnfile");

	for my $f (@cds) {
		
		my ($orfName, $start, $end, $upStreamSeq, $s, $e);

		if ($f->has_tag('locus_tag')) {
			$orfName = join('', $f->get_tag_values('locus_tag'));
			print OUTPUT ">" . $orfName;
		}
## added by jhn - some annotators are using "gene" instead of "locus_tag" which breaks the output - 2013-07-10:

		elsif ($f->has_tag('gene')) {
			$orfName = join('', $f->get_tag_values('gene'));
			print OUTPUT ">" . $orfName;
		}		    


		if ($f->location->strand > 0) { # ORF is on the plus strand
			$start = $f->location->start;
			$end = $f->location->end;
			
			# retrieve upstream sequence from entire sequence starting position $start-$length up to and including the intiation codon
			$s = $start-$length;
			$e = $start + 2;
			$upStreamSeq = $f->entire_seq()->subseq($s,$e);
			print OUTPUT " " . $s . ".." . $e . "\n";
			print OUTPUT $upStreamSeq . "\n";
		}
		else { # ORF is on the minus
			$start = $f->location->end;
			$end = $f->location->start;

			# retrieve "upstream" regions by grabbing the downstream sequence starting from the initiation codon and ending at $end+$length
			# and THEN REVERSE-COMPLEMENT
			$s = $start-2;
			$e = $start+$length;
			$upStreamSeq = revcom($f->entire_seq()->subseq($s, $e))->seq;
			print OUTPUT " complement(" . $s . ".." . $e . ")\n";
			print OUTPUT $upStreamSeq . "\n";
		}
	}
}
