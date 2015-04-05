#!/usr/bin/perl
use strict;
use warnings;

# Usage: perl ExtractFromMultiFast <file with list of IDs> <multifasta file>
# Created by: Andre Villegas 2008

## Program Info:
#
# Name: ExtractFromMultiFast
#
# Function: Parses through a multifasta file and 
# 	    extracts a single fasta corresponding to a given ID in a file...or something like that. 
#           OR does the reverse, i.e. remove all the IDs from the fasta file, creating a new file.
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2008-2009
# All Rights Reserved
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# Usage: perl ExtractFromMultiFast <ids file> <fasta file>
#
# History:
# 12 Feb 2008:			- Finished for Dion Lepp at GMBRU, Agriculture and Agri-food Canada
# 13 Feb 2008:			- Fixed output issue with chomp()
# 13 Feb 2009:			- Made the header look more professional.
#				- Changed so it outputs a multifasta file extractedORFs.ffn and 
#				  not separate fasta files	
# 20 Jan 2010:			- Added reverse logic, remove the sequences that are in the IDS file. New Sub.
# 8 Oct 2010:			- Fixed a flaw experienced in STEC project, i.e. required ID 
#				  n00_4067_v1_896 and n00_4067_v1_798, but it was just returning 
#				  the fasta for n00_4067_v1_79 TWICE
# 11 Mar 2010			- Added chomp($id) to cleanup $id for comparisons to work
#				- Switched the position of $id and $curr[0]. Now it's index($curr[0], $id)
#

my $fast = $ARGV[1];
my $ids = $ARGV[0];

sub extract() {
	open(IDS, "<$ids");
	open(OUT, ">extracted.fasta");
	while(<IDS>) {
		my($id) = $_;
		chomp($id); # Clean up the id
		my $fastaOut = "";
		my $found = 0;
		open(FAST, "<$fast");
		while(<FAST>) {
			my($line) = $_;
			chomp($line);
			if ((substr($line, 0,1) eq ">") && ($found != 1)) {
				my @curr = split(' ', substr($line, 1));
				#if (index($id, $curr[0]) > -1) {
				if ($id eq $curr[0]) {
					$found = 1;
					$fastaOut .= "$line\n";
					next;
				}
			}	
			elsif ((substr($line, 0,1) eq ">") && ($found)) {
				$found = 0;
				#open(OUT, ">$id\.txt");
				print OUT $fastaOut;
				$fastaOut = "";
				$found = 0;
				#close(OUT);
				last;
			}
			if ($found) {
				$fastaOut .= "$line\n"; # prints the last line of the fasta record and adds a newline, next iteration it will print to file.
			}			
		}
		close(FAST);
		if ($found) {
			print OUT $fastaOut;
		}
	}
	close(IDS);
	close(OUT);
}

sub reverseextract() {
        # save the ids into and array
	open(IDS, "<$ids");
	my @ids;
	while(<IDS>) {
		my($id) = $_;
		chomp($id); # Clean up the id
		push(@ids, $id);
	}
	close(IDS);

        open(OUT, ">reverseextracted.fasta");
	open(FAST, "<$fast");
	my $fastaOut = "";
	my $found = 0; # 1 if ID has matched
        while(<FAST>) {
		my($line) = $_;
		chomp($line); # clean up the line, remove newlines etc.
		if (substr($line, 0,1) eq ">") { # if the line starts with '>'
			if (($fastaOut ne "") && ($found !=1)) { # if the variable has stuff in it, print it.
				print OUT $fastaOut;
				$fastaOut = "";
			}
			$found = 0;
                	foreach my $id (@ids) { # start comparing to all the IDS in the ids file
				chomp($id);
                                my @curr = split(' ', substr($line, 1)); # grab everything after the '>' and then split with space as delim. note: substr(EXPR,OFFSET,LENGTH)A
				#print $id . "\n";
				#print $curr[0] . "\n";
				#print @curr;
                                #if (index($curr[0], $id) > -1) { 
				if ($curr[0] eq $id) {# see if the current id and the current line in fasta match. 
								 #note: index returns the first position of arg2 in arg1, otherwise -1
                                        $found = 1; # fasta ids match up.
                                        last;
                                }
                        }
		}
		if ($found !=1) {
			$fastaOut .= "$line\n";
		}
        }
	# reached the end of file, check if last sequence should be printed out.
	if (($fastaOut ne "") && ($found !=1)) { # if the variable has stuff in it, print it.
        	print OUT $fastaOut;
                $fastaOut = "";
        }
        close(FAST);
        close(OUT);
}
extract();
#reverseextract();
