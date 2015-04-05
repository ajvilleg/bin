#! /usr/bin/perl
# use strict;
# use warnings;

#Parser for the genotype_freq_* files of HapMap data

$Infile=$ARGV[0];
$Outfile=$ARGV[1];

$countLines=0;

# if ($ARGV < 2){
#	print "Usage: perl FileParser.pl Infile Outfile\n\n";
#	exit;
# }

@populations=("CEU", "CHB", "JPT", "YRI");
$numPops=@populations;

unless(open(INFILE, $Infile)){
	print "Cannot open $Infile";
	exit;
} #end unless

unless(open(OUTFILE, ">$Outfile")){  
	print "Cannot open $Outfile";
	exit;
} #end unless

my @fileLines=<INFILE>;
$headerLine=$fileLines[0];

@headers=split(' ', $headerLine);
print OUTFILE "$headers[0]\tPopulation\t$headers[1]\t$headers[2]\t$headers[3]\tRefAllele\tOtherAllele\t$headers[12]\t$headers[15]\t$headers[18]\t$headers[19]\n";

foreach my $nextLine (@fileLines){ #for each line in file (row in table)

   if ($countLines>0){ # to remove header line
    # if (($countLines>0)&&($countLines<30)){ # for testing

	my @dataVal=split(/ /, $nextLine); #data is space-delimitted

	$dbSnpID=$dataVal[0];
	$chromosome=$dataVal[1];
	$position=$dataVal[2];
	$strand=$dataVal[3];

	$refHomoGenotype=$dataVal[10];
	$countRefHomoGenotype=$dataVal[12];
	$heteroGenotype=$dataVal[13];
	$countHeteroGenotype=$dataVal[15];
	$otherHomoGenotype=$dataVal[16];
	$countOtherHomoGenotype=$dataVal[18];
	$countTotalGenotypes=$dataVal[19];
	
# Parse reference and other allele from genotypes
	$refAllele=substr($refHomoGenotype,0,1);
	$otherAllele=substr($otherHomoGenotype,0,1);
	my $population="";

# Parse population from file name
	for ($i=0; $i<$numPops;$i++){
		$nextPopulation=$populations[$i];
		if($Infile =~ m/$nextPopulation/i){ # to match string and ignore case
	 		$population=$nextPopulation;
		}
	}	
		print OUTFILE "$dbSnpID\t$population\t$chromosome\t$position\t$strand";
		print OUTFILE "\t$refAllele\t$otherAllele\t$countRefHomoGenotype\t$countHeteroGenotype\t$countOtherHomoGenotype\t$countTotalGenotypes";		
   } #end if count lines
	$countLines++;
} #end for each line

print "\nNumber of Lines: $countLines\n";
print "The End\n";
exit;
