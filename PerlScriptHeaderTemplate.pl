#! /usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Bio::SeqIO;

## Program Info:
#
# Name: <enter name here>
#
# Function: <description of what this does>
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
#
my ( $infile, $outfile );

GetOptions(
	'i|input=s' => \$infile,
	'o|output=s' => \$outfile
);

usage() unless $infile && $outfile;

sub usage {
	print <<USAGE;
<Name of Program>.pl	This tool does a lot of bullshit.

Usage:	[option]
	-i | --input	Path to input
	-o | --output	Path to output

Example:
perl <Name of Program>.pl -i inputfile -o outputfile

USAGE
	exit;
}

<Name of Method>();

exit;
