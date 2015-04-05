#! /usr/bin/perl
use strict;
use warnings;
use Bio::SearchIO;
use Bio::SearchIO::Writer::HTMLResultWriter;
use Getopt::Long;
Getopt::Long::Configure('bundling'); # allow 'bundling' options e.g. -alhvax reference: http://search.cpan.org/~jv/Getopt-Long-2.38/lib/Getopt/Long.pm#Bundling

## Program Info:
#
# Name: subtractiveHyb
#
# Function: Separates the unique ORFs in the query from the non-unique ones that
#  	    already found in the database.
#
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2008-2009
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# Usage: perl subtractiveHyb <file.blast>
#
# History:
# 12 Feb 2009:		- Coding started based on the BioPerl HOWTOs
# 				http://www.bioperl.org/wiki/HOWTO:Beginners#BLAST
# 				http://www.bioperl.org/wiki/HOWTO:SearchIO
# 				http://www.bioperl.org/wiki/HOWTO:Graphics
# 24 Mar 2009:		- Added findOther() which will be used to find plasmid related BACs
#				via text search through results
# 20 Jan 2010:		- Added runtime arguments and usage
# 29 Jun 2010:		- Added GetOptions Getopt::Long and Usage
#


#my $error_msg = "Try again pls."; # DEPRECATED by Getopt::Long
my ( $blastfile, $procedure );

GetOptions(
	'i|input=s' => \$blastfile,
	'p|proc=s' => \$procedure
);

usage() unless $blastfile && $procedure;

sub usage {
	print <<USAGE;
subtractiveHyb.pl		Separates the ORFS based on certain criteria from a BLAST report

Usage:	[options]
	-i | --input		Path to input blast file
	-p | --proc		Procedure type (unique/common/other/virdb)

Example:
subtractiveHyb.pl -i blastreport.txt -p unique

USAGE
	exit;
}		

#DEPRECATED#my $in = new Bio::SearchIO(-format => 'blast', 
                           #-file   => 'LF82vsALLECOLIexceptLF82.bls');
			   #-file   => 'LF82uniquesVSO83AllpredictedORFS_tblastx.bls');
			   #-file   => 'plLF82vsALLECOLIexceptLF82.bls');
			   #-file   => 'plLF82uniquesvsO83ALLpredictedORFS_tblastx.bls');
			   #-file => 'O83vsALLECOLI.bls');
			   #-file => 'UPECfaavsNonUPECAIEC_DB.blastp');

# DEPRECATED by Getopt::Long
# Read in blastfile
## Copied from John's search.pl code
## Handle input parameters:
## Does the input sequence exist: handle errors
# If $ARGV[0] is not blank, test for file's existence:
#if (defined $ARGV[0]) {
#        unless (-e $ARGV[0]) {
#                die ("\nError: Blast file \'$ARGV[0]\' does *not* exist> \n",
#                                        $error_msg, "\n");
#        }
#        $blastfile = $ARGV[0];
#}

die ("\nError: Blast file $blastfile does not exist or has wrong format", "\n") unless (-e $blastfile);
my $in = new Bio::SearchIO(-format => 'blast',
                           -file => $blastfile);
findUniques() if ($procedure eq "unique");
findCommon() if ($procedure eq "common");
findOther() if ($procedure eq "other");
virDbParse() if ($procedure eq "virdb");

exit;


#### FOR FINDING UNIQUE GENES ####
sub findUniques {
	my $writerhtml = new Bio::SearchIO::Writer::HTMLResultWriter();
	my $outhtml = new Bio::SearchIO(-writer => $writerhtml,
	                                 -file   => ">$blastfile.uniquegenes.html");
	open(OUT, ">$blastfile.uniquegenes.ids");
	while( my $result = $in->next_result) {
		my $goodhit = 0;
		#print	"Query= ", $result->query_name,
		#    	" Num_hits= ", $result->num_hits, "\n";
		#if ($result->num_hits < 1) { # no hits, therefore unique
			# get a result from Bio::SearchIO parsing or build it up in memory
		#	$outhtml->write_result($result);
		#	print OUT $result->query_name . "\n";
		#}
		#else { # there are hits but now we're checking if all are bad hits, i.e. "unique"
		if ($result->num_hits >= 1) {
			if ( my $hit = $result->next_hit ) {
				if ( my $hsp = $hit->next_hsp ) {
					if ( ( $hsp->evalue < 1e-2 ) && ( $hsp->percent_identity >= 80 ) && ( ( ( $hsp->length('query') )/( $result->query_length ) ) >= 0.8 ) ) { 
						# if e-value is less than 0.01 AND identity is >= 50% and the length of the query used in alignment is at least 50% of the total query length
						# means there's a least one good hit, don't want this. Not unique enough, the more stringent this is, the less good hits there are
						# which means more BAD hits.
						$goodhit = 1;
					}			
				}
			}
		}
		if ( $goodhit == 0 ) {
                        $outhtml->write_result($result);
                        print OUT $result->query_name . "\n";
                }
	}
	close(OUT);
}

#### FOR FINDING COMMON GENES ####
sub findCommon {
	my $writerhtml = new Bio::SearchIO::Writer::HTMLResultWriter();
	my $outhtml = new Bio::SearchIO(-writer => $writerhtml,
	                                 -file   => ">$blastfile.common.html");
	open(OUT, ">$blastfile.common.ids");
	while( my $result = $in->next_result) {
		if ($result->num_hits >= 1) {
			if ( my $hit = $result->next_hit ) {
				if ( my $hsp = $hit->next_hsp ) {
					if ( ( $hsp->evalue < 1e-2 ) && ( $hsp->percent_identity >=65 ) && ( ( ( $hsp->length('query') )/( $result->query_length ) ) >= 0.5 ) ) { 
						# means there's a least one good hit, we want this since is common between query and subject
						$outhtml->write_result($result);
						print OUT $result->query_name . "\n";
					}			
				}
			}
		}
	}
	close(OUT);
}

#### FOR FINDING GENES BASED ON OTHER CRITERIA ####
sub findOther {
	my $writerhtml = new Bio::SearchIO::Writer::HTMLResultWriter();
	my $outhtml = new Bio::SearchIO(-writer => $writerhtml,
	                                 -file   => ">$blastfile.html");
	open(OUT, ">$blastfile.ids");
	while( my $result = $in->next_result) {
		if ($result->num_hits >= 1) {
			if ( my $hit = $result->next_hit ) {
				if ( my $hsp = $hit->next_hsp ) {
					if ( ( $hsp->evalue < 1e-2 ) && ( $hsp->percent_identity >=35 ) && ( ( ( $hsp->length('query') )/( $result->query_length ) ) >= 0.5 ) ) { 
						# means there's a least one good hit, we want this since is common between query and subject
						$outhtml->write_result($result);
						print OUT $result->query_name . "\n";
					}			
				}
			}
		}
	}
	close(OUT);
}


sub virDbParse {
        my $writerhtml = new Bio::SearchIO::Writer::HTMLResultWriter();
        my $outhtml = new Bio::SearchIO(-writer => $writerhtml,
                                         -file   => ">$blastfile.html");
        open(OUT, ">$blastfile.ids");
	open(OUT2, ">$blastfile.csv");
	print OUT2 "Query,Hit,E-value,% Identity,Length of query used in alignment\n";
        while( my $result = $in->next_result) {
                if ($result->num_hits >= 1) {
                        if ( my $hit = $result->next_hit ) {
                                if ( my $hsp = $hit->next_hsp ) {
                                        if ( ( $hsp->evalue < 1e-2 ) && ( $hsp->percent_identity >=35 ) && ( ( ( $hsp->length('query') )/( $result->query_length ) ) >= 0.5 ) ) {
                                                # means there's a least one good hit, we want this since is common between query and subject
                                                $outhtml->write_result($result);
                                                print OUT $result->query_name . "\n";
						print OUT2 $result->query_name . "," . $hit->name . "," . $hsp->evalue . "," . $hsp->percent_identity . "," . ($hsp->length('query'))/($result->query_length) . "\n";
                                        }
                                }
                        }
                }
        }
        close(OUT);
	close(OUT2);
}


#my $goodhit = 0;
#while( my $result = $in->next_result ) {
#	if ( $result->num_hits >= 1 ) {
#	while( (my $hit = $result->next_hit) && ($goodhit == 0) ) {
#   		while( (my $hsp = $hit->next_hsp) && ($goodhit == 0) ) {
#    #if( $hsp->length('total') > 50 ) {
#     			if( $hsp->evalue < 1e-2 ) {
#     #if ( $hsp->percent_identity >= 75 ) {
#      				print 	"Query= ", $result->query_name, $result->query_description,
#					"Hit= ",       $hit->name, 
#            				",Length=",     $hsp->length('total'), 
#            				",Percent_id=", $hsp->percent_identity, "\n";
#     #} 
#    			}
#   		}  
#  	}
#	}
#}
