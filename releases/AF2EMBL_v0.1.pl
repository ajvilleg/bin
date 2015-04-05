#!/usr/bin/perl

#	Script to parse Glimmer3 and AutoFACT output into EMBL formatted
#	features for reading into Artemis & Kodon annotation environment.  The script
#	requires a glimmer output file and produces EMBL formatted output to STDOUT and can piped to an appropriate
#	output file, if not the EMBL format will be displayed on the screen.
#	Andre Villegas Laboratory for Foodborne Zoonoses, PHAC, June 18, 2008
#
# USAGE : AF2EMBL [glimmer *.predict file] [AutoFACT *.out file] [fasta file *.fna] > (output tab file) 
#
# History:
#
# 5 March 2009		- Fixed the complement coordinates by switching $start and $end
# 			  because it wasn't coming out in the GBK file after conversion
# 			- Added code to remove "Cluster: " in annotation description 
###################################################################################
my $Glimmer3_output = $ARGV[0];
my $AutoFACT_output = $ARGV[1];
my $FNAfile = $ARGV[2];
parse_glimmer($Glimmer3_output, $AutoFACT_output, $FNAfile);

###################################################################################
sub parse_glimmer
{
#subroutine variable declarations
my $glimmer;  		#filehandle for Glimmer3 input
my $af;			#filehandle for AutoFACT input
my $fna;		#filehandle for FASTA file input
my $output;		#filehandle for output
#my $buffer;		#input buffer
#my $FLAG_parse=0;	#FLAG to say it's time to parse
#my $FLAG_shadow=0;	#FLAG to say it's a shadowed gene
my @results;		#results array for the genes
#my $component;		#component of the result, ie gene, start and stop
#my $inx;		#index counter

#get these variables from arguments
$glimmer = $_[0];
$af = $_[1];
$fna = $_[2]; 
#$output  = $_[2];

open(GLIMMER, $glimmer) || die "cannot open the input $glimmer file";
open(AUTOFACT, $af) || die "cannot open the input $af file";

my @autoF = <AUTOFACT>;
chomp @autoF;
my $size = @autoF;
my $inx = 0;

# Count each nucleotide and output it, also, properly output the sequence in EMBL format, 60 nts per line, split in chunks of 10
open(FASTA, $fna) || die "cannot open the input $fna file";
my $ade = 0; # counter for Adenine
my $gua = 0; # counter for Guanine
my $cyt	= 0; # counter for Cytosine
my $thy = 0; # counter for Thymine
my $oth = 0; # counter for Other 'nucleotides'
my $total = 0; # counter for ALL nucleotides
my $seq = ""; # the sequence in one straight line and then reused later for final sequence output in EMBL format
while(<FASTA>) {
	if(/>/) {
		# skip the fasta line
	}
	else {
		$_ =~ s/\cM\n/\n/g; #Remove ^M (control+M) characters that are added when you edit the Fasta file in Mac OS, Windows or DOS
		chomp $_;
		$seq = $seq . $_;
	}
}
my @charseq = split(//, $seq);
$size = @charseq; # reusing for size of character array
$inx = 0; # reusing variable for counter
my $ten = 10;
my $sixty = 60;
$seq = "     "; # reusing for final sequence output in EMBL format, put the first 5 spaces.
while ($total < ($size) ) {
	if ($sixty == 0) {
		for ($i=0; $i<(length($size)+5-length($total)); $i++) {
			$seq = $seq . " ";
		}
		$seq = $seq . $total . "\n";
		$seq = $seq . "     ";
		$ten = 10;
		$sixty = 60;
	}
	if ($ten == 0) {
		$seq = $seq . " ";
		$ten = 10;
	}
	# Determine which nucleotide the current character is
	if (uc($charseq[$total]) eq 'A') {
		$ade++;
	}
	elsif (uc($charseq[$total]) eq 'G') {
		$gua++;
	}
	elsif (uc($charseq[$total]) eq 'C') {
		$cty++;
	}
	elsif (uc($charseq[$total]) eq 'T') {
		$thy++;
	}
	else {
		$oth++;
	}
	$seq = $seq . $charseq[$total];
	$total++;
	$ten--;
	$sixty--;
}
for ($i=0; $i<(length($size)+5-length($total)+$sixty+int($sixty/10)); $i++) {
	$seq = $seq . " ";
}
$seq = $seq . $total . "\n";
$seq = $seq . "//";
# seq will be printed at the bottom of the file so later on.

	# print the header part of the EMBL file (needed to convert to GBK)
	@name = split(/\./, $af);
	print("ID   $name[0]\n");
	print("AC   $name[0]\n");
	print("KW   .\n");
	print("DE\n");
	print("OS\n");
	print("FH   Key             Location/Qualifiers\n");
	print("FH\n");
	print("FT   source           1..$total\n");

	# print CDSs first before the final sequence
	while(<GLIMMER>){
	if(/>/) #checks if the character > is in the current line
	{
		#skips the fasta line	
	}	
	else
	{
		@results = split;
		$gene = $results[0];
		$start = $results[1];
		$end = $results[2];

		#get annotation from AutoFACT output file
		@currAnn = split(/\t/, $autoF[$inx]); #split the tab-delimited file
		
		#each annotation line stored in currAnn has these columns starting from 0: 
		#0 - SequenceID	
		#1 - Source	
		#2 - Accession	
		#3 - Locus Name	
		#4 - Description	
		#5 - EC number	
		#6 - E-value	
		#7 - Percent Identity	
		#8 - Informative Hit	
		#9 - Function	
		#10 - Pathway	
		#11 - GeneOntology terms	
		#12 - Alignment Score	
		#13 - Annotation Source
		until ($currAnn[0] eq $gene && $currAnn[1] eq "AutoFACT") {
			$inx++;
			if ($inx > $size-1) { exit 0; } #we are past the end of file
			@currAnn = split(/\t/, $autoF[$inx]);
		}
		
		# precondition: we now have the right annotation to use.

		if($end < $start)
		{
		        print("FT   CDS              complement($end..$start)\n");
			#print("FT                   \/note=\"predicted using Glimmer\"\n");
			#print("FT                   \/gene=\"\"\n");
		}
		else
		{
			print("FT   CDS              $start..$end\n");
			#print("FT                   \/note=\"predicted using Glimmer\"\n");
			#print("FT                   \/gene=\"\"\n");
		}		
		print("FT                   \/product=\"$currAnn[3]\"\n");
		print("FT                   \/gene=\"$gene\"\n");
		
		# added to remove 'Cluster: ' clause in note
		$currAnn[4] =~ s/Cluster: //g;
		print("FT                   \/note=\"$currAnn[4]\"\n");
		}	
	}

# close the Glimmer and AutoFACT files
close(GLIMMER);
close(AUTOFACT);

print "SQ   Sequence " . $total . " BP " . $ade . " A; " . $cty . " C; " . $gua . " G; " . $thy . " T; " . $oth . " other;\n"; # print the SQ line
print $seq; # print the sequence in finish of the EMBL file
close(FASTA);
}
