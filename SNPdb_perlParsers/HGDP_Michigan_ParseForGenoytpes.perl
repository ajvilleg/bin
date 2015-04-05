#! /usr/bin/perl
# use strict;
# use warnings;

#Parser for the files of HGDP_Michigan data

$numInfoRows=6;
$numInfoColumns=7;
@Populations=("EUROPE", "MIDDLE_EAST", "CENTRAL_SOUTH_ASIA", "OCEANIA", "AMERICA", "AFRICA", "EAST_ASIA");
$numPopulations=@Populations;
my %outFilesHash;

$Infile=$ARGV[0];
$Outfile=$ARGV[1];
$SNPfile="SNP_list.txt";

# if ($ARGV < 2){
#	print "Usage: perl FileParser.pl Infile Outfile\n\n";
#	exit;
# }
for($i=0; $i<$numPopulations; $i++){

  $nextPopulation=$Populations[$i];
  $outFilesHash{$nextPopulation}=$nextPopulation."_".$Outfile;
}
@outFiles=values(%outFilesHash);
print "Out Files: @outFiles";

unless(open(INFILE, $Infile)){
	print "Cannot open input file: $Infile";
	exit;
} #end unless
unless(open(SNPFILE, ">$SNPfile")){
	print "Cannot open input file: $SNPfile";
	exit;
} #end unless

my @fileLines=<INFILE>;
$headerLine=$fileLines[0];
$chromosomeLine=$fileLines[2];
$positionLine=$fileLines[3];

@ListOfSNPs=split(/ /, $headerLine);
@ListOfChromosomes=split(/ /, $chromosomeLine);
@ListOfPositions=split(/ /, $positionLine);

$numSNPs=@ListOfSNPs;
$numFileLines=@fileLines;
# $numSNPs=20; # for testing

print "\nFile: $Infile \nNumber of SNPs: $numSNPs";

$outfileHeader="Individual Population ";
print SNPFILE "dbSNP_ID Chromosome Position";

for ($i=0; $i<$numSNPs; $i++){
	
	print SNPFILE "\n$ListOfSNPs[$i] ";
	print SNPFILE "$ListOfChromosomes[$i] ";
	print SNPFILE "$ListOfPositions[$i]";
	$outfileHeader.=" $ListOfSNPs[$i]";
}
# print "\nOutfile Header: $outfileHeader";

for ($i=0; $i<$numPopulations; $i++){
  $nextPopulation=$Populations[$i];
  $nextOutFile=$outFilesHash{$nextPopulation};
  open(NEXTOUTFILE, ">$nextOutFile");
  # print NEXTOUTFILE "$outfileHeader";
  print NEXTOUTFILE "dbSNP_ID $headerLine";
  print NEXTOUTFILE "Chromosome $chromosomeLine";
  print NEXTOUTFILE "Position $positionLine";
  close (NEXTOUTFILE);
}

$countPairs=0;
$totalNumPairs=($numFileLines-$numInfoLines)/2;

for ($j=0; $j<$totalNumPairs; $j++) {	#for each line in file (row in table)
# for ($j=0; $j<30; $j++) {	# for testing

  $subjectIndex=($numInfoRows-1)+2*$j; # to work with genotype data rows
  $firstLine=$fileLines[$subjectIndex];
  $secondLine=$fileLines[1+$subjectIndex];
  @firstDataVals=split(/ /, $firstLine); #data is space-delimitted
  @secondDataVals=split(/ /, $secondLine); #data is space-delimitted

  if ($firstDataVals[0] eq $secondDataVals[0]) { # to check lines paired properly
    $thisSubjectID=$firstDataVals[0];
    $thisPopulation=$firstDataVals[4];

    $thisOutFile=$outFilesHash{$thisPopulation};
    # print "OutFile: $thisOutFile";

    open(OUTFILE, ">>$thisOutFile"); # want to append data
    print OUTFILE "$thisSubjectID";

    for ($i=0; $i<$numSNPs; $i++) {
      $nextIndex=$numInfoColumns+$i;
      print OUTFILE " $firstDataVals[$nextIndex]$secondDataVals[$nextIndex]";
    }
    close(OUTFILE);
  } 
  else {
    print "\nGenoypes not paired at line: $countLines :$firstDataVals[0] and $secondDataVals[0]";
  }
  $countPairs++;
}				#end for each line

print "\nNumber of Pairs: $countPairs\n";
print "The End\n";
exit;
