#! /usr/bin/perl
use warnings;
use strict;
use Bio::SearchIO;

## Program Info:
#
# Name: percentUniqueRegionFromPairWise
#
# Function: From a resulting output file from bl2seq pairwise blastn alignment between two genomes, this will
#	    calculate the percent of unique regions of the query versus the subject
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 20XX-20XX
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# Usage: perl percentUniqueRegionFromPairWise <file.blast>
#
# History:
# 9 March 2010:		- Coding started based on the BioPerl HOWTOs
#                               http://www.bioperl.org/wiki/HOWTO:Beginners#BLAST
#                               http://www.bioperl.org/wiki/HOWTO:SearchIO
#                               http://www.bioperl.org/wiki/HOWTO:Graphics
#

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
my $in = new Bio::SearchIO(-format => 'blast',
                           -file => $blastfile,
			   -report_type => 'blastn'); # Added this report_type to be able to parse bl2seq

my $totalLength=0;
my $result;
my $dblength=0;

while ($result =  $in->next_result) {
	while ( my $hit = $result->next_hit ) {
		if ($dblength==0) {
			$dblength = $hit->length;
		}
		while ( my $hsp = $hit->next_hsp ) {
				#print $hsp->length('query');
				#print "\n";
				$totalLength += $hsp->length('query');
		}
	}
}
print "1st sequence length: $totalLength\n";
print "2nd sequence length: $dblength\n";
print "1st % unique region vs 2nd: " . ($dblength/$totalLength)*100 . "\n";



