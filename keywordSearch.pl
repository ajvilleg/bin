#! /usr/bin/perl
use warnings;
use strict;
use Bio::SearchIO;
use Bio::SearchIO::Writer::HTMLResultWriter;
use Text::CSV;
use Class::Struct;

## Program Info:
#
# Name: keywordSearch
#
# Function: Parses blast output and searches for keywords (loaded in from CSV file)
# Format of keyword CSV file: Keyword, Functional Category, Relevance/Function
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
# Usage: perl keywordSearch.pl <file.blastp> <keywordsfile.csv>
#
# History:
# 5 Jan 2010:		- Code reused from subtractiveHyb.pl which was based on the ff:
# 				http://www.bioperl.org/wiki/HOWTO:Beginners#BLAST
# 				http://www.bioperl.org/wiki/HOWTO:SearchIO
# 26 Jan 2010:		- Fixed bugs. Changes so it can also grab hits from a specific bacteria strain.

# Initialize variables:
my $error_msg = "Try again pls.";
my $csv = Text::CSV->new(); # from http://perlmeme.org/tutorials/parsing_csv.html
my %keywords = ();
my %results = ();
my $bacteriaNameToAvoid = "";
my $bacteriaNameToFind = "";

# Initialize class # from http://www.xav.com/perl/lib/Class/Struct.html
struct( keyword => [
	key => '$', # keyword (unique)
	category => '$',
	relevance => '$',
]);

#struct( result => [
#	key  => '$',
#	output => '@',
#]);
	

# Command line params
my $blastfile;
my $keywordfile;


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
			   -file => $blastfile);

# Read in keywordfile
## Copied from John's search.pl code
## Handle input parameters:
## Does the input sequence exist:  handle errors
# If $ARGV[0] is not blank, test for file's existence:
if (defined $ARGV[1]) {
  unless (-e $ARGV[1]) {
    die("\nError: Keyword file \'$ARGV[1]\' does *not* exist. \n", 
				$error_msg, "\n");
  }
  $keywordfile = $ARGV[1];
}

open (KEYWORDS, "<", $keywordfile) or 
  die ("\nError: Cannot open file $keywordfile: $!\n",
       $error_msg, "\n");

# Store the keywords into a hash of keyword structs
while (<KEYWORDS>) {
	chomp;
	if ($csv->parse($_)) {
		my @columns = $csv->fields();
		my $k = $columns[0];
		my $c = $columns[1];
		my $r = $columns[2];
		if ($k eq "Keyword") {
			next;
		}
		$keywords{$k} = keyword->new( key => $k,
					      category => $c,
				   	      relevance => $r,
					    );	
	}
	else {
		my $err = $csv->error_input;
		print "Failed to parse line: $err";
	}
}
close(KEYWORDS);

sub skipIt() {
	if (($bacteriaNameToAvoid eq "") && ($bacteriaNameToFind eq "")) { # If the variables are not set.
		return 0; # Continue execution
	}
	my @hits = @_;
	foreach my $hit (@hits) {
		my $descmod = $hit->description;
		while ( my $hsp = $hit->next_hsp ) {
			if ( ( $hsp->evalue < 1e-2 ) && ( $hsp->percent_identity >= 75 ) ) {
		                if (($bacteriaNameToAvoid ne "") && ($bacteriaNameToFind eq "") && ($descmod =~ m/$bacteriaNameToAvoid/i)) { # if $bacteriaNameToAvoid is set and if the current result 
	                     			                                                                                  #is a hit to $bacteriaNameToAvoid e.g. Ecoli
	                		return 1; # Skip it
	        	        }
				if (($bacteriaNameToAvoid eq "") && ($bacteriaNameToFind ne "") && ($descmod =~ m/$bacteriaNameToFind/i)) { # $bacteriaNameToFind is set and is FOUND. Continue processing.
	                        	return 0;
	   			}
			}
		}
	}
	if (($bacteriaNameToAvoid ne "") && ($bacteriaNameToFind eq "")) {
		return 0;
	}
	else {
		return 1; # Skip It
	}
}

sub test() {
	my $skip = 0;
        while( my $result = $in->next_result) {
                my @hits = sort {$b->bits <=> $a->bits} $result->hits; # From http://www.bioperl.org/wiki/HOWTO:SearchIO, sort by score
		foreach my $hit (@hits) {
			my $descmod = $hit->description;
			while ( my $hsp = $hit->next_hsp ){
                        #	if ( ( $hsp->evalue < 1e-2 ) && ( $hsp->percent_identity >= 75 ) ) {
                                	if (($bacteriaNameToAvoid ne "") && ($bacteriaNameToFind eq "") && ($descmod =~ m/$bacteriaNameToAvoid/i)) { # if $bacteriaNameToAvoid is set and if the current result 
                                        	                                                                                          #is a hit to $bacteriaNameToAvoid e.g. Ecoli
	                                        $skip = 1;
						last;
	                                }
	                                elsif (($bacteriaNameToFind ne "") && ($bacteriaNameToAvoid eq "") && !($descmod =~ m/$bacteriaNameToFind/i)) { # $bacteriaNameToFind is set and is NOT found. skip this result.
	                                	$skip = 1;
						last;
					}
	                 #       }
			}
			if ($skip == 1) {
				last;
			}
                }
		if ($skip == 0) {
			print $result->query_name . $result->query_description . "\n";
		}
		else {
			$skip = 0;
		}
	}
}

sub findKeywords() {
	my $skip = 0;
	print "\"KEYWORD\",\"QUERY\",\"HIT\",\"% IDENTITY\"\n";
	while( my $result = $in->next_result) {
		my @hits = sort {$b->bits <=> $a->bits} $result->hits; # From http://www.bioperl.org/wiki/HOWTO:SearchIO, sort by score
		$skip = &skipIt(@hits);
		if ( $skip == 0 ) {
			foreach my $hit (@hits) {
				$hit->rewind;
				while ( my $hsp = $hit->next_hsp ) { 
					if ( ( $hsp->evalue < 1e-2 ) && ( $hsp->percent_identity >= 75 ) && ( ( ( $hsp->length('query') )/( $result->query_length ) ) >= 0.5 ) ) { 
						# if e-value is less than 0.01 AND identity is >= 50% and the length of the query used in alignment is at least 50% of the total query length
						# means there's a least one good hit
						foreach my $key (keys %keywords) {
							my $descmod = $hit->description;
							if ($descmod =~ m/\s$key.*/i) { #($hit->description =~ m/\s$key.*/i) { # if the keyword is found
								my $category = $keywords{$key}->category; # Category this keyword belongs to
								#my $toSave = "KEYWORD: $key\n". $writerhtml->to_string($result) . "\n\n";
								my $toSave = "\"$key\",";
								$toSave .= "\"" . $result->query_name ." ". $result->query_description . "\",";
								$toSave .= "\"" . $hit->name ." ". $hit->description . "\",\"" . $hsp->percent_identity . "\"\n";
								#print $toSave;
								if (exists $results{$category}) { # if the category already exists in the hash
									$results{$category} .= $toSave; # just add hit to the results
									#print "Category $category exists. Here's what's in it:\n";
									#print "$results{$category}\n";
									#print "Here's what I want toSave: $toSave\n\n";
								}
								else { # add the a new category and new hit 
									$results{$category} = $toSave;
									#print "Category $category does not exist. Adding it and saving $toSave\n\n";
								}
								$skip = 1;
								last; # keyword already found. Result printed. Skip to next result.  
							}
						}
						if ($skip == 1) {
							last;	# keyword should be found as above. Skip to next result.
						}
					}
				}
				if ($skip == 1) {
					last;   # keyword should be found as above. Skip to next result.
				}
			}	
		}
		$skip = 0;
	}
}

#test();
&findKeywords();
foreach my $cat (keys %results) {
	print "\"CATEGORY: $cat\",\"\",\"\"\n";
	print $results{$cat};
	print "\n";
}
