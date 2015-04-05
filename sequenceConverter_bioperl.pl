#!/usr/bin/perl

## Program Info:
#
# Name: sequenceConverter_bioperl
#
# Rationale: Readseq fails for me sometimes. 
#
# Function: Converts input file to different formats
#
# Usage: perl sequenceConverter_bioperl.pl <input file> <output filename> 
#   NOTE: Have to change the input and output formats below first
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2009-2010
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# History:
# v0.0	Nov 18 2009	- Created this script

use Bio::SeqIO;

my $input = $ARGV[0];
my $output = $ARGV[1];

#$in = Bio::SeqIO->new(-file => "$input" , '-format' => 'Genbank');
#$out = Bio::SeqIO->new(-file => ">$output" , '-format' => 'EMBL');
$in = Bio::SeqIO->new(-file => "$input" , '-format' => 'genbank');
$out = Bio::SeqIO->new(-file => ">$output" , '-format' => 'fasta');

while ( $seq = $in->next_seq() ) {
	$out->write_seq($seq);
}
