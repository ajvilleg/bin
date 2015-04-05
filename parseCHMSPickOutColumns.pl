#! /usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
#use Text::CSV;
use Tie::Handle::CSV; # used to access fields in CSV file by name!!! from here: http://perlmeme.org/tutorials/parsing_csv.html
#use DBI:CSV; # used to access data in a csv file with SQL statements! from the same link above.

## Program Info:
#
# Name: parseCHMSPickOutColumns.pl
#
# Function: This parses through the large CHMS file (currently called CHMS9E4H) and picks out certain columns
#	    and creates a new CSV file.
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
# History:
# v0.0 28 Mar 2011		- Finished initial version
# v0.1 19 Apr 2011		- Added some new rows
my ( $infile, $outfile );

GetOptions(
	'i|input=s' => \$infile,
	'o|output=s' => \$outfile
);

usage() unless $infile && $outfile;

sub usage {
	print <<USAGE;
parseCHMSPickOutColumns.pl	This tool does a lot of bullshit.

Usage:	[option]
	-i | --input	Path to input CHMS csv file
	-o | --output	Path to output csv file.

Example:
perl parseCHMSPickOutColumns.pl -i <inputfile> -o <outputfile>

USAGE
	exit;
}

parse();

exit;

sub parse {
	my $fh = Tie::Handle::CSV->new($infile, header => 1); # ref: http://perlmeme.org/tutorials/parsing_csv.html

	open(OUT, ">$outfile") or die("$!\n");
	print OUT "CLINICID,";
	print OUT "SITE,";
	print OUT "SITESTRT,";
	print OUT "SITEEND,";
	print OUT "V2_YEAR,"; #v0.1
	print OUT "V2_MTH,"; #v0.1
	print OUT "V2_DAY,"; #v0.1
	print OUT "DATE,"; #v0.1
	print OUT "V2_HOUR,"; #v0.1
	print OUT "DHH_AGE,";
	print OUT "DHH_SEX,";
	print OUT "SDC_22,";
	print OUT "SDC_23A,";
	print OUT "SDC_23B,";
	print OUT "SDC_23C,";
	print OUT "SDC_24A,";
	print OUT "SDC_24B,";
	print OUT "SDC_24C,";
	print OUT "SDC_24D,";
	print OUT "SDC_24E,";
	print OUT "SDC_24F,";
	print OUT "SDC_24G,";
	print OUT "SDC_24H,";
	print OUT "SDC_24I,";
	print OUT "SDC_24J,";
	print OUT "SDC_24K,";
	print OUT "SDC_24L,";
	print OUT "SEB_12,";
	print OUT "MDC_11,";
	print OUT "MDC_12A,";
	print OUT "MDC_12B,";
	print OUT "MDC_12C,";
	print OUT "MDC_12D,";
	print OUT "MDC_12E,";
	print OUT "CCCF1,";
	print OUT "LAB_VITD\n";
	while (my $csv_line = <$fh>) {
		print OUT $csv_line->{'CLINICID'};
		print OUT ",";
		print OUT $csv_line->{'SITE'};
		print OUT ",";
		print OUT $csv_line->{'SITESTRT'};
		print OUT ",";
		print OUT $csv_line->{'SITEEND'};
		print OUT ",";
		print OUT $csv_line->{'V2_YEAR'}; #v0.1
		print OUT ",";
		print OUT $csv_line->{'V2_MTH'}; #v0.1
		print OUT ",";
		print OUT $csv_line->{'V2_DAY'}; #v0.1
		print OUT ",";

		# JOINING THESE COLUMNS #v0.1
		print OUT $csv_line->{'V2_YEAR'};
		if (length($csv_line->{'V2_MTH'}) != 2) {
			print OUT "0" . $csv_line->{'V2_MTH'};
		}
		else {
			print OUT $csv_line->{'V2_MTH'};
		}
		if (length($csv_line->{'V2_DAY'}) != 2) {
			print OUT "0" . $csv_line->{'V2_DAY'};
		}
		else {
			print OUT $csv_line->{'V2_DAY'};
		}
		print OUT ",";
		# END OF JOINED COLUMNS

		print OUT $csv_line->{'V2_HOUR'}; #v0.1
		print OUT ",";
		print OUT $csv_line->{'DHH_AGE'};
		print OUT ",";
		print OUT $csv_line->{'DHH_SEX'};
		print OUT ",";
		print OUT $csv_line->{'SDC_22'};
		print OUT ",";
		print OUT $csv_line->{'SDC_23A'};
		print OUT ",";
		print OUT $csv_line->{'SDC_23B'};
		print OUT ",";
		print OUT $csv_line->{'SDC_23C'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24A'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24B'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24C'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24D'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24E'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24F'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24G'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24H'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24I'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24J'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24K'};
		print OUT ",";
		print OUT $csv_line->{'SDC_24L'};
		print OUT ",";
		print OUT $csv_line->{'SEB_12'};
		print OUT ",";
		print OUT $csv_line->{'MDC_11'};
		print OUT ",";
		print OUT $csv_line->{'MDC_12A'};
		print OUT ",";
		print OUT $csv_line->{'MDC_12B'};
		print OUT ",";
		print OUT $csv_line->{'MDC_12C'};
		print OUT ",";
		print OUT $csv_line->{'MDC_12D'};
		print OUT ",";
		print OUT $csv_line->{'MDC_12E'};
		print OUT ",";
		print OUT $csv_line->{'CCCF1'};
		print OUT ",";
		print OUT $csv_line->{'LAB_VITD'};
		print OUT "\n";
	}
	close $fh;
	close(OUT);
	
}
