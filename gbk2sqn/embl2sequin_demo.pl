#!/usr/bin/perl

use strict;
use lib 'sequin_tools';
use emblparser;
use sequin_compiler;

my $name = __FILE__;
my $usage = <<HOWTO

__________________________________________________________________

Usage: $name <emblfile>


This program converts an EMBL file to the sequin table format.
To get your annotation in EMBL format, save it in Artemis like
this: "File > Save an Entry As > EMBL format".

The output is sent to STDOUT. If you want it in a file, call it
like this:

$name R6.embl > R6_sequintable.txt

Known problems:

- The program is sensitive to any input that deviates from
  what it expects. Check the EMBL files provided to see what
  they should look like.
- The program is slow for large inputs. It might take half
  an hour to convert a big EMBL file.

For questions or suggestions mail me: nuhn\@rhrk.uni-kl.de
There is an online version here:
http://nbc11.biologie.uni-kl.de/sequin/index_sequin.shtml

__________________________________________________________________

HOWTO
;

my $emblfile = shift;

unless (-e $emblfile) {
	print $usage;
	exit;
}


my $embl = readFile($emblfile);


# Parse the EMBL file, sort according to the start coordinates
my @sorted = sort {

	$a->{location}->{coordinate}->{start} <=> $b->{location}->{coordinate}->{start}

} @{parse_embl($embl)};

my $sequin_table = compile_sequin_table(\@sorted);

die "An error occurred while converting your file!" unless ($sequin_table);

my $compiled_embl  = ">Feature <Insert title here>\n".$sequin_table;
#added by Andre Villegas to remove qualifier quotes
#$compiled_embl =~ s/"//g; #moved task to emblparser
#added by Andre Villegas to change translation tables from Kodon default 1 to 11 (Bacterial)
$compiled_embl =~ s/transl_table\t1\n/transl_table\t11\n/g;
print $compiled_embl;
exit;








sub readFile {

	my $filename = shift;
	local $/;	
	
	# check if file exists
	if (!-e $filename) {			
			die "Can't find file: $filename error!";
	}
	
	open IN, $filename or die "Could not open $filename !";
	my $content = <IN>;
	close IN;
	return $content;
}
