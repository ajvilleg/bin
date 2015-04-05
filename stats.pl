#!/usr/bin/perl

## Program Info:
#
# Author: John Nash
#
# Copyright (c) National Research Council of Canada, 2002,
#   all rights reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#   for use, and as long as the author/copyright attributions
#   are not removed.
#
##

use strict;
use warnings;

##  Handle the input sequence.
## Does the input sequence exist:  handle errors
# If $ARGV[0] is not blank, test for file's existence:
if (defined $ARGV[0]) {
    unless (-e $ARGV[0]) {
	die("\nError: Sequence file \'$ARGV[0]\' does *not* exist. \n");
    }
    open (FILE, $ARGV[0]);
}

# If it has come in from a redirection or pipe, 
#  check it is bigger than 0:
else {
    my $fh = *STDIN;
    unless ((-p $fh) or (-s $fh)) {
	die("\nError: Piped sequence file does *not* exist. \n");
    }
    *FILE = *STDIN;
}


## Read in the sequence from a FASTA file:
#   For multiple sequences, concatenate them with ">".
#   There is no reason for multiple sequences to be thus analysed
#   unless they are contigs from a single project.

my ($seq_name, $seq_length, $seq_str, $count);
# read the header:
$count = 0;
while (<>) {
    s/\r\n/\n/g;
    chomp;
    if (/^>/)  {
	$seq_name = substr($_, 1, length $_);
	$seq_str .= ">" if ($count > 0);
	$count++;
    }
    else {
	$seq_str .= uc $_;
    }
}

# Some final sequence processing:
$seq_length = length $seq_str;
$seq_str = uc $seq_str;

# Eliminate all nonACGTs:
$seq_str =~ tr/XNATGCBDKRVHMYSW/XXATGCXXXXXXXXXX/;


# Calculating incomings ACGT content:
my ($As, $Cs, $Gs, $Ts, $totalACGT, $fractA, $fractC, $fractG, $fractT);
$As = ($seq_str =~ tr/A//);
$Cs = ($seq_str =~ tr/C//);
$Gs = ($seq_str =~ tr/G//);
$Ts = ($seq_str =~ tr/T//);
$totalACGT = $As + $Cs + $Gs + $Ts;

# Convert to 2 decimal places:
$fractA = sprintf("%0.4f", $As/$totalACGT)*100;
$fractC = sprintf("%0.4f", $Cs/$totalACGT)*100;
$fractG = sprintf("%0.4f", $Gs/$totalACGT)*100;
$fractT = sprintf("%0.4f", $Ts/$totalACGT)*100;

# Output the data:

# If the incoming sequence has some degenerate bases. Warn user.
if ($totalACGT < $seq_length) {
	print "The analysed sequence has ", $seq_length-$totalACGT, 
	" degenerate bases.  This may skew the results.\n";
}

print "Segments: $count; Total bases: $seq_length\n";
print "%A: $fractA; %C: $fractC; %G: $fractG; %T: $fractT;   %GC: ", 
    ($fractG + $fractC), "\n";

