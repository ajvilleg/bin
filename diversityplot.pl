#! /usr/bin/perl
use strict;
use warnings;
use Bio::SearchIO;
use Getopt::Long;
Getopt::Long::Configure('bundling'); # allow 'bundling' options e.g. -alhvax reference: http://search.cpan.org/~jv/Getopt-Long-2.38/lib/Getopt/Long.pm#Bundling
use Text::CSV;
use Class::Struct;
use Switch;
use GD::Graph::bars;
use GD::Graph::hbars;
#require 'save.pl';

## Program Info:
#
# Name: diversityplot
#
# Function: Parse output from blast of reference strain vs other strains and 
#	    creates a diversity plot (stacked histogram) showing if the gene in the reference 
#	    strain is present in the other strains.
#
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2010
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# History:
# 7 Jul 2010:		- Coding started
#

my ( $blastfile, $strainlist, $csv, %strainGroup, @results, @locustag, @histData );

struct( strain => [
	id => '$',
	group => '$',
]);

GetOptions(
	'i|input=s' => \$blastfile,
	's|strains=s' => \$strainlist
);

usage() unless $blastfile && $strainlist;

sub usage {
	print <<USAGE;
diversityplot.pl 	Parse output from blast of reference strain vs other strains and 
			creates a diversity plot (stacked histogram) showing if the gene in the reference 
			strain is present in the other strains.

Usage:	[options]
	-i | --input	Path to input blast file
	-s | --strains  Path to Strain List file with a list of strains and groups (see below for format)

Example:
diversityplot.pl -i blastreport.txt -p strain_list.txt

Strain List File Format:
01_5870,B
01_6372,B
03_4186,B
cl106,B
cl1,B
n01_2454,B
r82f2,B
06_5121,C
cl3,C
ec6_990,C
n00_4067,C
ec2_051,D
n01_1625,D
n02_2616,D
n02_4495,D
ec3_208,E
ec4_453,E
ec6_448,E
ec6_626,E

USAGE
	exit;
}

die ("\nError: Blast file $blastfile does not exist or has wrong format", "\n") unless (-e $blastfile);

my $in = new Bio::SearchIO(-format => 'blast',
			   -file => $blastfile);

readStrains();
parseBlast();
#makeTable();
createHistTable();
printHistTableCSV();
printHistTableGnuPlot();

exit;

sub readStrains {
	open(STRAINS, "<$strainlist") or die("\nError: Cannot open file $strainlist: $!\n");
	my $i = 0;
	$csv = Text::CSV->new();
	%strainGroup = ();
	while (<STRAINS>) {
		chomp;
		if ($csv->parse($_)) {
			my @column = $csv->fields();
			my $s = $column[0];
			my $g = $column[1];
			$strainGroup{$s} = strain->new( id => $i,
							group => $g,
						      );
			$i++;
		}
		else {
			my $err = $csv->error_input;
			print "Failed to parse line: $err";
			exit;
		}
	}
	close(STRAINS);
}


sub parseBlast {
	my $i = 0; #gene number
	my $size += keys %strainGroup;
	while ( my $result = $in->next_result ) {

		$locustag[$i] = $result->query_name;

		my @hits = sort {$b->bits <=> $a->bits} $result->hits; # From http://www.bioperl.org/wiki/HOWTO:SearchIO, sort by score

		my $j = 0;

                for ( $j=0; $j<$size; $j++) {
                	$results[$i][$j] = 0;
                } 

		#while ( my $hit  = $result->next_hit ) {
		foreach my $hit (@hits) {

			while ( my $hsp = $hit->next_hsp ) {
				#if ( $hsp->length('total') > 50 ) {
				#	if ( $hsp->percent_identity >= 75 ) {
				#		print "Query=",	$result->query_name,
				#		" Hit=",	$hit->name,
				#		" Length=",	$hsp->length('total'),
				#		" Percent_id=",	$hsp->percent_identity,	
				#		" E-value=",	$hsp->evalue, "\n";
				#	}
				#}

				if ( $hsp->evalue < 1e-2 ) {
					my $target = $hit->name;
					$target =~ s/_v1.*//i;

					if ( $results[$i][$strainGroup{$target}->id] == 0 ) {
						# Probe/Target Identiy - %Identity recalculated to take into account total length of query 
						my $pti = (($hsp->percent_identity)*($hsp->length('total')))/($result->query_length);
						# PTI cutoff in Chad/Ed's study = 80%
						if ($pti >= 80) {
							#$results[$i][$strainGroup{$target}->id] = $hsp->percent_identity;
							$results[$i][$strainGroup{$target}->id] = $pti;
						}
						else { # did not meet cutoff
						       # leave it at default value 0
						}

					}

					else { # already set
						# skip
					}
				}
				last;
			}
		}
		$i++;
	}
}

sub makeTable {
	my @strArray;
	# create an array of strain names sorted by ID number for proper printing of results.	
	foreach my $str (keys %strainGroup) {
		$strArray[$strainGroup{$str}->id] = $str;
	}
	
	open(TABLE, ">table.csv");
	print TABLE "\"Locus Tag\"";

	# print header line of strain names with group letter
	for (my $i=0; $i<scalar(@strArray); $i++) {
		
		print TABLE ",\"", $strArray[$i], " (", $strainGroup{$strArray[$i]}->group, ")\"";
	}


	print TABLE "\n";
	# print the results
 	for (my $k=0; $k<scalar(@locustag); $k++) {
	
		print TABLE $locustag[$k];
	
		for (my $j=0; $j<scalar(@strArray); $j++) {
			
			print TABLE ",", $results[$k][$j];
		
		}
		print TABLE "\n";
	}
	
	close(TABLE);
}

sub createHistTable {
	my @strArray;

        # create an array of strain names sorted by ID number for proper printing of results.   
        foreach my $str (keys %strainGroup) {
                $strArray[$strainGroup{$str}->id] = $str;
        }
	
	#initialize @histData with zero values
	for (my $i=0; $i<scalar(@locustag); $i++) {
		for (my $j=0; $j<4; $j++) {
			$histData[$i][$j] = 0;
		}
	}

	
	# convert results to histogram table, counting how many positive results per group
	for (my $g=0; $g<scalar(@locustag); $g++) {
		
		for (my $h=0; $h<scalar(@strArray); $h++) {
			
			if ( $results[$g][$h] == 0 ) {
			
				switch ( $strainGroup{$strArray[$h]}->group ) {
					case "B" { $histData[$g][0]++; }
					case "C" { $histData[$g][1]++; }
					case "D" { $histData[$g][2]++; }
					case "E" { $histData[$g][3]++; }
					else 	 { print "GROUP NOT FOUND!"; print "Not found\n"; }
				}
			}
			else {
				# skip it
			}
		}
	}

}

sub printHistTableCSV {

        open(HISTABLE, ">histable.csv");

        print HISTABLE "\"Locus Tag\"";

        print HISTABLE ",B,C,D,E\n";

        for (my $k=0; $k<scalar(@locustag); $k++) {

                print HISTABLE $locustag[$k];

                for (my $p=0; $p<4; $p++) {

                        print HISTABLE ",", $histData[$k][$p];
                }
                print HISTABLE "\n";
        }
        close(HISTABLE);	

}

sub printHistTableGnuPlot {

        open(HISTABLE, ">histable.dat");

        print HISTABLE "#Locus Tag";

        print HISTABLE "\tB\tC\tD\tE\n";

        for (my $k=0; $k<scalar(@locustag); $k++) {

                print HISTABLE $locustag[$k];

                for (my $p=0; $p<4; $p++) {

                        print HISTABLE "\t", $histData[$k][$p];
                }
                print HISTABLE "\n";
        }
        close(HISTABLE);

}
