#! /usr/bin/perl
# use strict;
# use warnings;

# Parser for the genotype_freq_* files of HapMap data
# History (Andre Villegas):
# 29 March 2011		- changed all tabs \t to commas to create a CSV instead
#			- modified the script to completely match the table definition of HapMap_SNP_GenotypeCount in SNP_db

$Infile=$ARGV[0];
$Outfile=$ARGV[1];

$countLines=0;

# if ($ARGV < 2){
#	print "Usage: perl FileParser.pl Infile Outfile\n\n";
#	exit;
# }

@populations=("ASW", "CEU", "CHB", "CHD", "GIH", "JPT", "LWK", "MEX", "MKK", "TSI", "YRI");
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
#print OUTFILE "$headers[0],Population,$headers[1],$headers[2],$headers[3],RefAllele,OtherAllele,$headers[12],$headers[15],$headers[18],$headers[19]\n";
print OUTFILE "dbSNP_ID,Population,Chromosome,Position,Strand,RefAllele,OtherAllele,Count_WW,Count_WV,Count_VV,Total\n";


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
		print OUTFILE "$dbSnpID,$population,$chromosome,$position,$strand";
		print OUTFILE ",$refAllele,$otherAllele,$countRefHomoGenotype,$countHeteroGenotype,$countOtherHomoGenotype,$countTotalGenotypes";		
   } #end if count lines
	$countLines++;
} #end for each line

print "\nNumber of Lines: $countLines\n";
print "The End\n";
exit;
