#!/opt/perl/ActivePerl/5.12.3/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::SeqIO;

## Program Info:
#
# Name: gbk2tbl
#
# Function: Convert a Genbank format file to tab-delimited Sequin table format as described here: http://www.ncbi.nlm.nih.gov/Sequin/table.html
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2010-XXXX
# All Rights Reserved.
# 
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# History:
# 17 Aug 2010:			- Coding started

my ( $gbkfile, $outfile );

GetOptions(
	'i|input=s' => \$gbkfile,
	'o|output=s' => \$outfile
);

usage() unless $gbkfile && $outfile;

sub usage {
	print <<USAGE;
gbk2tbl.pl	Convert a Genbank format file to tab-delimited Sequin table format as described here: http://www.ncbi.nlm.nih.gov/Sequin/table.html

Usage:	[option]
	-i | --input	Path to input Genbank file
	-o | --output	Path to output Sequin table file

Example:
gbk2tbl.pl -i input.gbk -o output.tbl

USAGE
	exit;
}

convertGBKtoTBL();

exit;

sub convertGBKtoTBL {
	my $gbk = Bio::SeqIO->new(-file => $gbkfile );
	my $seq = $gbk->next_seq;

	open(OUTPUT, ">$outfile");

	print OUTPUT ">Feature " . $seq->display_id . " " . $seq->accession_number . " \n";
	
	for my $feat_object ($seq->get_SeqFeatures) {

		if ( $feat_object->primary_tag eq "gene" ) {
			
			my ( $start, $end );		
	
			if ( $feat_object->location->strand > 0) {
				$start = $feat_object->location->start;
				$end = $feat_object->location->end;
			}
			else {
				$start = $feat_object->location->end;
				$end = $feat_object->location->start;
			}
			
			print OUTPUT $start . "\t" . $end . "\t" . "gene\n";
			
			if ($feat_object->has_tag('gene')) {
				print OUTPUT "\t\t\t" . "gene\t";
				for my $val ($feat_object->get_tag_values('gene')) {
					print OUTPUT $val;
				}
				print OUTPUT "\n";
			}

			if ($feat_object->has_tag('locus_tag')) {
				print OUTPUT "\t\t\t" . "locus_tag\t";
				for my $val ($feat_object->get_tag_values('locus_tag')) {
					print OUTPUT $val;
				}
				print OUTPUT "\n";
			}

		}
		elsif ( $feat_object->primary_tag eq "CDS" ) {
			my ( $start, $end );
			
			# if the coordinates contain a split or join
			if ( $feat_object->location->isa('Bio::Location::SplitLocationI') ) {
				my $firstline = 1;				
				for my $location ( $feat_object->location->sub_Location ) {
					
					if ( $feat_object->location->strand > 0 ) {
						$start = $location->start;
						$end = $location->end;
					}
					else {
						$start = $location->end;
						$end = $location->start;
					}

					if ($firstline == 1) {
						print OUTPUT $start . "\t" . $end . "\t" . "CDS\n";
						$firstline = 0;
					}
					else {
						print OUTPUT $start . "\t" . $end . "\n";
					}
				}
			}
			else { # normal coordinates
			
				if ( $feat_object->location->strand > 0) {
					$start = $feat_object->location->start;
					$end = $feat_object->location->end;
				}
				else {
					$start = $feat_object->location->end;
					$end = $feat_object->location->start;
				}

				print OUTPUT $start . "\t" . $end . "\t" . "CDS\n";
			}
			
			if ($feat_object->has_tag('gene')) {
				print OUTPUT "\t\t\t" . "gene\t";
				for my $val ($feat_object->get_tag_values('gene')) {
					print OUTPUT $val;
				}
				print OUTPUT "\n";
			}

			if ($feat_object->has_tag('locus_tag')) {
				print OUTPUT "\t\t\t" . "locus_tag\t";
				for my $val ($feat_object->get_tag_values('locus_tag')) {
					print OUTPUT $val;
				}
				print OUTPUT "\n";
			}

			if ($feat_object->has_tag('product')) {
				print OUTPUT "\t\t\t" . "product\t";
				for my $val ($feat_object->get_tag_values('product')) {
					print OUTPUT $val;
				}
				print OUTPUT "\n";
			}

			if ($feat_object->has_tag('note')) {
				print OUTPUT "\t\t\t" . "note\t";
				for my $val ($feat_object->get_tag_values('note')) {
					print OUTPUT $val;
				}
				print OUTPUT "\n";
			}

		}

	}

	close(OUTPUT);
}

