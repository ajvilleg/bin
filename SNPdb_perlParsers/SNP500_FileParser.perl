#! /usr/bin/perl
# use strict;
# use warnings;

# Parser for the allgenes.tab file of SNP500cancer data
# History (Andre Villegas):
# 29 March 2011		- changed all tabs \t to commas to create a CSV instead
#			- modified the script to completely match the table definition of SNP500_GenotypeCount in SNP_db

$Infile=$ARGV[0];
$Outfile=$ARGV[1];
$startDataCol=14;
$countLines=0;

# if ($ARGV < 2){
#	print "Usage: perl FileParser.pl Infile Outfile\n\n";
#	exit;
# }

@populations=("Afr", "Cauc", "Hisp", "PacRim");
@genotypes=("WW", "WV", "VV");
$numPopulations=@populations;
$numGenotypes=@genotypes;

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

@headers=split('\t', $headerLine);
#print OUTFILE "$headers[0],$headers[1],$headers[2],$headers[6],$headers[7],$headers[8],Population,CountWW,CountWV,CountVV,Total";
print OUTFILE "SNP500_ID,dbSNP_ID,SNP_ID,$headers[2],$headers[6],$headers[7],$headers[8],Population,Count_WW,Count_WV,Count_VV,Total";


foreach my $nextLine (@fileLines){ #for each line in file (row in table)

	my @dataVal=split('\t', $nextLine); #data is tab-delimitted

	# We want both SNP500 ID and dbSNP ID
	$snpID=$dataVal[0];
	$dbsnpID=$dataVal[1];
	$gene=$dataVal[2];
	$region=$dataVal[6];
	$majorAllele=$dataVal[7];
	$minorAllele=$dataVal[8];

	my $lengthData=@dataVal;
	$countFields=0;
	$hasData="yes";

	my $countWW=0;
	my $countWV=0;
	my $countVV=0;
	my $countAfr=0;

# Use major and minor allele to define genotypes (NOTE- some genotypes are recorded as +/-)
	if ( ($majorAllele =~ /[AGCT]/) && ($minorAllele =~ /[AGCT]/) ) {
		$genotypeWW=$majorAllele.$majorAllele;
		$genotypeVW=$minorAllele.$majorAllele;
		$genotypeWV=$majorAllele.$minorAllele;
		$genotypeVV=$minorAllele.$minorAllele;
	}
	elsif( ($majorAllele =~ /[+-]/) && ($minorAllele =~ /[+-]/) ){
		$genotypeWW=$majorAllele."/".$majorAllele;
		$genotypeVW=$minorAllele."/".$majorAllele;
		$genotypeWV=$majorAllele."/".$minorAllele;
		$genotypeVV=$minorAllele."/".$minorAllele;		
	}
	else{ # alleles not defined so no genotype data
		$hasData="no";	
	}
	# print "\nAllelotypes: ".$majorAllele."/".$minorAllele;
	# print "\nMajor genotype: ".$genotypeWW;

#We want to calculate count of 3 genotypes for each population

	my @countGenoAfr=(0,0,0);
	my @countGenoCauc=(0,0,0);
	my @countGenoHisp=(0,0,0);
	my @countGenoPacRim=(0,0,0);
	
	if (($countLines>0)&&($hasData eq "yes")){   # first line is header and remove lines with no allelotypes
	# if (($countLines>0)&&($countLines<20)&&($hasData eq "yes")){   # for testing

     	  	for ($i=$startDataCol; $i<($lengthData-1);$i++){ # for each data field in row
		# for ($i=$startDataCol; $i<=$startDataCol+25;$i++){ # for testing

			$countFields++;
 			my $nextSubject=$headers[$i];
			my $nextGenotype=$dataVal[$i];
			my $population;
			my $genotype;

# Population is indicated by first letter in subject ID which is row header

			if ($nextSubject =~ /^a/){
				$population="Afr";
				$countAfr++;
			}
			elsif ($nextSubject =~ /^c/){
				$population="Cauc";
			}
			elsif ($nextSubject =~ /^h/){
				$population="Hisp";
			}
			elsif ($nextSubject =~ /^p/){
				$population="PacRim";
			}
			else {
				print "\nNo subject: $nextSubject at line: $countLines";
			}

# Find genotype for subject
				if ($nextGenotype eq $genotypeWW){
					$genotype='WW';
					$countWW++;
				}	
				elsif ($nextGenotype eq $genotypeVV){
					$genotype='VV';
					$countVV++;
				}	
				elsif ($nextGenotype eq $genotypeWV){
					$genotype='WV';
					$countWV++;
				}
				elsif ($nextGenotype eq $genotypeVW){
					$genotype='WV';
					$countWV++;
				}
				else { # genotype information is missing for many subjects and snps
					#print "No genotype at line ".$countLines." field ".$countFields;
				} 

# Count genotypes per population
				if ($population eq "Afr"){

					if ($genotype eq "WW"){
						$countGenoAfr[0]++;
					}
					elsif ($genotype eq "WV"){
						$countGenoAfr[1]++;
					}
					elsif ($genotype eq "VV"){
						$countGenoAfr[2]++;
					}
				}
				elsif ($population eq "Cauc"){

					if ($genotype eq "WW"){
						$countGenoCauc[0]++;
					}
					elsif ($genotype eq "WV"){
						$countGenoCauc[1]++;
					}
					elsif ($genotype eq "VV"){
						$countGenoCauc[2]++;
					}
				}
				elsif ($population eq "Hisp"){

					if ($genotype eq "WW"){
						$countGenoHisp[0]++;
					}
					elsif ($genotype eq "WV"){
						$countGenoHisp[1]++;
					}
					elsif ($genotype eq "VV"){
						$countGenoHisp[2]++;
					}
				}
				elsif ($population eq "PacRim"){

					if ($genotype eq "WW"){
						$countGenoPacRim[0]++;
					}
					elsif ($genotype eq "WV"){
						$countGenoPacRim[1]++;
					}
					elsif ($genotype eq "VV"){
						$countGenoPacRim[2]++;
					}
				}
				else {
					print "\nNo population: line ".$countLines." field ".$countFields;
				}
	  	} #end for each data field in row

		#$commonInfo="$snpID,$dbsnpID,$gene,$region,$majorAllele,$minorAllele";
		$commonInfo="$snpID,$dbsnpID,$dbsnpID,$gene,$region,$majorAllele,$minorAllele";
		print OUTFILE "\n$commonInfo,Afr,$countGenoAfr[0],$countGenoAfr[1],$countGenoAfr[2]";
		print OUTFILE ",".($countGenoAfr[0]+$countGenoAfr[1]+$countGenoAfr[2]);

		print OUTFILE "\n$commonInfo,Cauc,$countGenoCauc[0],$countGenoCauc[1],$countGenoCauc[2]";
		print OUTFILE ",".($countGenoCauc[0]+$countGenoCauc[1]+$countGenoCauc[2]);

		print OUTFILE "\n$commonInfo,Hisp,$countGenoHisp[0],$countGenoHisp[1],$countGenoHisp[2]";
		print OUTFILE ",".($countGenoHisp[0]+$countGenoHisp[1]+$countGenoHisp[2]);

		print OUTFILE "\n$commonInfo,PacRim,$countGenoPacRim[0],$countGenoPacRim[1],$countGenoPacRim[2]";	
		print OUTFILE ",".($countGenoPacRim[0]+$countGenoPacRim[1]+$countGenoPacRim[2]);	
	} #end if count lines
	$countLines++;
} #end for each line

print "\nNumber of Lines: $countLines\n";
print "The End\n";
exit;
