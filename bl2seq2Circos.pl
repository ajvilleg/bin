#! /usr/bin/perl
use warnings;
use strict;
use Bio::SearchIO;

## Program Info:
#
# Name: bl2seq2Circos
#
# Function: Parses bl2seq report and extracts required info for Circos
#  	    already found in the database.
#
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2010-20XX
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# Usage: perl bl2seq2Circos <filename>
#
# History:
# 24 May 2010:		- Coding started
#				http://search.cpan.org/~sendu/bioperl/Bio/SearchIO/blast.pm#bl2seq_parsing

my $error_msg = "Try again pls.";
my $blastfile;


# Read in blastfile
## Copied from John's search.pl code
## Handle input parameters:
## Does the input sequence exist: handle errors
# If $ARGV[0] is not blank, test for file's existence:
if (defined $ARGV[0]) {
        unless (-e $ARGV[0]) {
                die ("\nError: Blast file \'$ARGV[0]\' does *not* exist> \n",
                                        $error_msg, "\n");
        }
        $blastfile = $ARGV[0];
}
my $in = new Bio::SearchIO->new(-format => 'blast',
				-file => $blastfile,
				-report_type => 'blastn'); # need to include report_type for bl2seq

parse();

sub parse {
	open(OUT, ">$blastfile.links.txt");
	my $linkctr = 150;
	while( my $result = $in->next_result ) {
		while( my $hit = $result->next_hit ) {
			while( my $hsp = $hit->next_hsp) {
				if ( $hsp->percent_identity >= 85 ) {
					print OUT "link_$linkctr pl1 " . $hsp->start('query') . " " . $hsp->end('query') . " color=chr12";
					
					if ( $hsp->start('query') > $hsp->end('query') ) {
						print OUT "inverted=1";
					}
					print OUT "\n";

					print OUT "link_$linkctr pl5 " . $hsp->start('hit') . " " . $hsp->end('hit') . " color=chr12";
					
					if ( $hsp->start('hit') > $hsp->end('hit') ) {
						print OUT "inverted=1";
					}
					print OUT "\n";
					$linkctr++;
				}
			}
		}
	}
	close(OUT);
}
