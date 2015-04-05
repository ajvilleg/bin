#! /usr/bin/perl
# use strict;
# use warnings;

#Parser for the HGDP_Michigan transposed datafiles

$Infile=$ARGV[0];
$Outfile=$ARGV[1];
$thisPopulation=$ARGV[2];
$indexFirstDataCol=3;
$countLines=0;

# if ($ARGV < 2){
#	print "Usage: perl FileParser.pl Infile Outfile Population\n\n";
#	exit;
#}

@genotypes=("WW", "WV", "VV");

unless(open(INFILE, $Infile)){
  print "Cannot open $Infile";
  exit;
}				#end unless

unless(open(OUTFILE, ">$Outfile")){  
  print "Cannot open $Outfile";
  exit;
}				#end unless

my @fileLines=<INFILE>;
$headerLine=$fileLines[0];
$numFileLines=@fileLines;
# $numFileLines=20; #for testing

@headers=split(" ", $headerLine);
$outfileHeader=$headers[0];
$outfileHeader.="\tPopulation\t";
for ($i=1; $i<$indexFirstDataCol; $i++) {
  $outfileHeader.="$headers[$i]\t";
}
print OUTFILE "$outfileHeader\tRefAllele\tOtherAllele\tCountWW\tCountWV\tCountVV\tTotal";

for($i=1; $i<$numFileLines; $i++){ #for each line in file (row in table)excluding header line.

  $nextLine=$fileLines[$i];
  my @dataFields=split(" ", $nextLine); #data is space-delimitted
  $numDataFields=@dataFields;
  $dbsnpID=$dataFields[0];
  $thisChromosome=$dataFields[1];
  $thisPosition=$dataFields[2];
  @arrayGenotypes=@dataFields[$indexFirstDataCol..$numDataFields];
  $numGenoVals=@arrayGenotypes;

  # print "\n\nArray Genotypes: @arrayGenotypes Number: $numGenoVals";

# Get the alleles
 if ($numGenoVals>1){	

   $listOfGenotypes=join(" ", @arrayGenotypes);
   $theseAlleles=getAlleles($listOfGenotypes);

    print "\nTwo Alleles: $theseAlleles";
   @twoAlleles=split("/", $theseAlleles);
  
  # Count number of each genotype
  my $countWW=0;
  my $countWV=0;
  my $countVV=0;
  my $countTotal=0;
# Use first and second allele to define genotypes
  my $firstAllele=$twoAlleles[0];
  my $secondAllele=$twoAlleles[1];

  if ($firstAllele =~ m/[AGCT]/i){
      my $thisGenotypeWW=$firstAllele.$firstAllele;
      print "\nGenotypeWW=$thisGenotypeWW";
      if ($secondAllele =~ m/[AGTC]/i){
	my $thisGenotypeWV=$firstAllele.$secondAllele;
	my $thisGenotypeVW=$secondAllele.$firstAllele;
	my $thisGenotypeVV=$secondAllele.$secondAllele;

	for ($j=0; $j<$numGenoVals;$j++){ # for each data field in row
	  $thisGenotype=$arrayGenotypes[$j];
	# Find genotype for subject
	  if ($thisGenotype eq $thisGenotypeWW) {
	    $countWW++;
	  }
	  elsif ($thisGenotype eq $thisGenotypeWV) {
	    $countWV++;
	  }
	  elsif ($thisGenotype eq $thisGenotypeVW) {
	    $countWV++;
	  }
	  elsif ($thisGenotype eq $thisGenotypeVV) {
	    $countVV++;
	  }
	}
      }
      else{
      for ($j=0; $j<$numGenoVals;$j++){ # for each data field in row
	$thisGenotype=$arrayGenotypes[$j];
	# Find genotype for subject
	if ($thisGenotype eq $thisGenotypeWW) {
	  $countWW++;
	}
      }
    }
      print "\nGenotypeWW: $countWW GenotypeVV: $countVV";
   }
  $commonInfo="$dbsnpID\t$thisPopulation\t$thisChromosome\t$thisPosition\t$firstAllele\t$secondAllele";
    print OUTFILE "\n$commonInfo\t$countWW\t$countWV\t$countVV";
    print OUTFILE "\t".($countWW+$countWV+$countVV); # count total
} # end if $numGenoVals>0
  else{
    print "\nSNP: $dbsnpID: No genotype data";
  }
  $countLines++;
}   #end for each line


print "\nNumber of Lines: $countLines\n";
print "The End\n";

###******************###
###   Subroutines    ###
###******************###

sub getAlleles{
  $allele1="N";
  $allele2="N";

  $n=$_[0];  # string passed to subroutine

  my @matchesA = ($n =~ /A/g); $countA=@matchesA;
  my @matchesT = ($n =~ /T/g); $countT=@matchesT;
  my @matchesG = ($n =~ /G/g); $countG=@matchesG;
  my @matchesC = ($n =~ /C/g); $countC=@matchesC;

  @countBases=($countA, $countT, $countG, $countC);
  @sortedCounts = sort{$b <=> $a}@countBases; # sorted in descending order

# Keys cannot be identical so if 2 counts are equal increment one
  if (($sortedCounts[0]>0)&&($sortedCounts[1]>0)){
    if ($sortedCounts[0]==$sortedCounts[1]){ # check if two counts are equal
      if ($countA==$sortedCounts[0]){$countA++;}
      elsif ($countT==$sortedCounts[0]){$countT++;}
      elsif ($countC==$sortedCounts[0]){$countC++;}
    }
  }
  %hashCounts=($countA, "A", $countT, "T", $countC, "C", $countG, "G");
  @hashKeys = keys(%hashCounts);
  @sortedKeys = sort{$b <=> $a}@hashKeys; # sorted in descending order
  # print "\nSorted Keys: @sortedKeys";
 
  if ($sortedKeys[0]>0){
    $allele1=$hashCounts{$sortedKeys[0]};
    if ($sortedKeys[1]>0){
      $allele2=$hashCounts{$sortedKeys[1]};   
    }  
  }		 
  print "\n\nMatches A:$countA C:$countC G:$countG T:$countT";
  return "$allele1/$allele2";	
}

