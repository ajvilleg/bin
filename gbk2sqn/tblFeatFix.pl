#!/usr/bin/perl
use strict;
# tblFeatFix.pl
# Copy the Fasta line from fsa to the <Insert title here> in tbl file.
# Andre Villegas
# Created on Sept 3, 2008
# To use, type:
# ./tblFeatFix.pl (.fsa) (.tbl) > outfile
# $ARGV[0] - the Fasta file
# $ARGV[1] - the tbl file

my $FASTA = "";
open FSA, "<", $ARGV[0] or die $!;
while (<FSA>) {
	my @array = split(//, $_); # split each line by character
	if ($array[0] eq ">") {    # check if there's a > character, the Fasta line
		$FASTA = substr($_, 1, scalar(@array)-1); # grab the Fasta line but remove the >
		last;
	}
}
close(FSA);

my $SKIP = 0;
open TBL, "<", $ARGV[1] or die $!;
print ">Feature " . $FASTA; # print the Feature line on the table file
while (<TBL>) {
	if ($SKIP == 1) {
		print $_;
	}
	else {
		$SKIP = 1; # skip the Feature line to be replaced by previous printing above
	}
}
close(TBL);
