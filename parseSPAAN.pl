#! /usr/bin/perl
use warnings;
use strict;

## Program Info:
#
# Name: parseSPAAN.pl
#
# Function: parses SPAAN (adhesin finder) output and outputs to standard output a FASTA text of predicted adhesins based on a minimum threshold Pad-value score
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
# History:
#
# 23 November 2009	- Created first version
#
# Usage: perl parseSPAAN.pl <minimum Pad-value score> <spaan output file> <fasta file> > predictedadhesins.fasta
#	e.g. parseSPAAN.pl 0.51 NRG857CvsECOLI_noLF82noO83_uniques.spaan NRG857CvsECOLI_noLF82noO83_uniques.faa > blah.txt
# 
##################################################################################

my $spaan = $ARGV[1];
my $threshold = $ARGV[0];
my $fasta = $ARGV[2];
parse_SPAAN($spaan, $threshold, $fasta);

##################################################################################

sub println {
    local $\ = "\n";
    print @_;
}

sub parse_SPAAN {

my $spaan = $_[0];
my $threshold = $_[1];
my $fasta = $_[2];

open (SPAAN, "<$spaan") || die "cannot open the input $spaan file";

while (<SPAAN>) {
	chomp $_;
	my @stuff = split('\t+', $_); #split on 1 ore more tabs
	if ($stuff[0] eq "SN") {
		# skip this line, these are the headers
	}
	else {
		# this is the stuff we need
		# $stuff[0] = SN
		# $stuff[1] = Pad-value
		# $stuff[2] = Protein name Fasta line
		my $sn = $stuff[0];
		my $score = $stuff[1];
		my $fastaline = $stuff[2];
	
		if ($score >= $threshold) {
			open (FASTA, "<$fasta") || die "cannot open the input $fasta file";
			my $fastaOut = "";
			my $found = 0;
			while(<FASTA>) { ## code reusedd from ExtractFromMultiFasta.pl
				my $line = $_;
				chomp($line);
				if ((substr($line, 0,1) eq ">") && ($found != 1)) {
					#my @curr = split(' ', substr($line, 1)); # this will split the fasta line into chunks
					#if (index($id, $curr[0]) > -1) { ## this is if the substring is found in the current fasta line
					if ($line eq $fastaline) { #compare the lines directly from the fasta and spaan input
						$found = 1;
						$fastaOut .= "$line"."|"." SPAANno.$sn,"."score=$score\n";
						next;
					}
				}	
				elsif ((substr($line, 0,1) eq ">") && ($found)) {
					$found = 0;
					print $fastaOut;
					$fastaOut = "";
					$found = 0;
					last;
				}
				if ($found) {
					$fastaOut .= "$line\n"; # prints the last line of the fasta record and adds a newline, next iteration it will print to file.
				}			
			}
			close(FASTA);
			if ($found) {
				print $fastaOut;
			}
	
		}
	}
}

close (SPAAN);
#close (FASTA);
}
