#!/usr/bin/perl
use strict;
# emblcleanforsqn.pl
# Remove the header lines from EMBL file (ID,XX,AC,KW,DE,OS,FH)
# Andre Villegas
# Version 1.0
# Created on Sept. 3, 2008
# To use script, type:
# ./emblcleanforsqn.pl infile > outfile

my $FTfound = 0;
while (<>) {
	if ($FTfound == 1) {
		print $_;
	}
	else {
		my @array = split(/ /,$_);
		if ($array[0] eq "FT") {
			$FTfound = 1;
			print $_;		
		}
	}
}
