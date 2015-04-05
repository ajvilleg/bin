#! /usr/bin/perl
use warnings;
use strict;
use Bio::SeqIO;
use Class::Struct;

## Program Info:
#
# Name: removeAllCDSwithXsFromGBK.pl
#
# Function: Parses a newly annotated Genbank file and searches for CDS's with translations that have X's. Remove and put in a separate file. This is so that the intergenic script can run on it.
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2010-2***
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# Usage: perl removeALLCDSwithXsFromGBK.pl <file.gbk>
#
# History:
# 29 Jan 2010:		- Code reused from keywordSearch.pl and used the ff. references:
#				http://www.bioperl.org/wiki/HOWTO:Feature-Annotation
#

# Initialize variables:
my $error_msg = "Try again pls.";


# Command line params
my $gbkfile;
my $out;


# Read in GBK file
## Copied from John's search.pl code
## Handle input parameters:
## Does the input sequence exist: handle errors
# If $ARGV[0] is not blank, test for file's existence:
print "Reading Genbank...";
if (defined $ARGV[0]) {
	unless (-e $ARGV[0]) {
		die ("\nError: Genbank file \'$ARGV[0]\' does *not* exist> \n",
					$error_msg, "\n");
	}
	$gbkfile = $ARGV[0];
}
my $seqio_object = Bio::SeqIO->new(-file => $gbkfile, -format => 'Genbank' );
my $seq_object = $seqio_object->next_seq;
print "Done\n";

$out = Bio::SeqIO->new(-file => ">clean$gbkfile" , '-format' => 'Genbank');

sub test() {
	for my $feat_object ($seq_object->get_SeqFeatures) {          
   		print "primary tag: ", $feat_object->primary_tag, "\n";          
   		for my $tag ($feat_object->get_all_tags) {             
      			print "  tag: ", $tag, "\n";             
      			for my $value ($feat_object->get_tag_values($tag)) {                
			        print "    value: ", $value, "\n";             
      			}          
   		}       
	}
}

sub findXs() {
	#print "Searching for virulence factors...\n";
	for my $feat_object ($seq_object->get_SeqFeatures) {
		if ($feat_object->primary_tag eq "CDS") {
			my @gene;
			my @note;
			my @product;
			my @locus_tag;
			push @gene, $feat_object->get_tag_values("gene") if ($feat_object->has_tag("gene"));
			push @note, $feat_object->get_tag_values("note") if ($feat_object->has_tag("note"));
			push @product, $feat_object->get_tag_values("product") if ($feat_object->has_tag("product"));
			push @locus_tag, $feat_object->get_tag_values("locus_tag") if ($feat_object->has_tag("locus_tag"));
			#foreach my $fac (keys %virfacts) {
			#	if (("@gene" =~ m/^$fac$/i) || ("@note" =~ m/^$fac\s/i) || ("@note" =~ m/\s$fac$/i) || ("@note" =~ m/\s$fac\s/i) || ("@product" =~ m/^$fac\s/i) || ("@product" =~ m/\s$fac$/i) || ("@product" =~ m/\s$fac\s/i)) {
			#		print "\"$fac\",\"@locus_tag\",\"";
			#		print $virfacts{$fac}->function;
			#		print "\"\n";
			#	}
			#}
		}		
	}
}

test();
