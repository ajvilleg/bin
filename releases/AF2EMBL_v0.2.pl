#!/usr/bin/perl

#	Script to parse Glimmer3 and AutoFACT output into EMBL formatted
#	features for reading into Artemis & Kodon annotation environment.  The script
#	requires a glimmer output file and produces EMBL formatted output to STDOUT and can piped to an appropriate
#	output file, if not the EMBL format will be displayed on the screen.
#	Andre Villegas Laboratory for Foodborne Zoonoses, PHAC, June 18, 2008
#
# USAGE : AF2EMBL [glimmer *.predict file] [AutoFACT *.out file] [fasta file *.fna] > (output EMBL file) 
#
# History:
#
# v0.1	5 March 2009		- Fixed the complement coordinates by switching $start and $end
# 			  	  because it wasn't coming out in the GBK file after conversion
# 				- Added code to remove "Cluster: " in annotation description 
# 			
# v0.11	22 May 2009		- Changed so that the first part of the Description (currAnn(4)) should be the "product", (before n=#)
#
# v0.2	28 Oct 2009		- Change spacing for CDS. 
#				- Added missing semi-colon after BP (Sequence length SQ code).
#				- Changed spacing in bottom full sequence between dna and position (from 5 to 3).
#				- Changed DNA sequence from uppercase to lowercase
#				- Added more lines to the source tag
#				- Added more needed info to the ID line, The will have to be modified depending on what is being annotated.
#				  Based on this site: http://www.ebi.ac.uk/embl/Documentation/User_manual/usrman.html#3_4_1
# v0.21	29 Oct 2009		- Use Bio::SeqIO to extract CDS (trunc) and to translate for /translation tag
# v0.22	23 Nov 2009		- added '<' for read only for each of the open file calls
#
###################################################################################
use Bio::Seq;
use Bio::SeqIO;
#require "/home/avillegas/bin/parsetRNAScan-SE.pl";

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
my $transl_table = 11; # codon translation table

#get these variables from arguments
$glimmer = $_[0];
$af = $_[1];
$fna = $_[2]; 
#$output  = $_[2];

open(GLIMMER, "<$glimmer") || die "cannot open the input $glimmer file";
open(AUTOFACT, "<$af") || die "cannot open the input $af file";

my @autoF = <AUTOFACT>;
chomp @autoF;
my $size = @autoF;
my $inx = 0;

# Count each nucleotide and output it, also, properly output the sequence in EMBL format, 60 nts per line, split in chunks of 10
open(FASTA, "<$fna") || die "cannot open the input $fna file";
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
my $spaceBtwSeq_Pos = 3;
$seq = "     "; # reusing for final sequence output in EMBL format, put the first 3 spaces.
while ($total < ($size) ) {
	if ($sixty == 0) {
		for ($i=0; $i<(length($size)+$spaceBtwSeq_Pos-length($total)); $i++) {
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
	my $currChar = lc($charseq[$total]);
	if ($currChar eq 'a') {
		$ade++;
	}
	elsif ($currChar eq 'g') {
		$gua++;
	}
	elsif ($currChar eq 'c') {
		$cty++;
	}
	elsif ($currChar eq 't') {
		$thy++;
	}
	else {
		$oth++;
	}
	$seq = $seq . $currChar;
	$total++;
	$ten--;
	$sixty--;
}
for ($i=0; $i<(length($size)+$spaceBtwSeq_Pos-length($total)+$sixty+int($sixty/10)); $i++) {
	$seq = $seq . " ";
}
$seq = $seq . $total . "\n";
$seq = $seq . "//";
# seq will be printed at the bottom of the file so later on.
close(FASTA);

# print the header part of the EMBL file (needed to convert to GBK)
@name = split(/\./, $af);
print("ID   $name[0]; SV 1; circular; genomic DNA; HTG; PRO; $total BP.\n");
print("XX\n");
print("AC   $name[0]\n");
print("XX\n");
print("DE\n");
print("XX\n");
print("KW   .\n");
print("XX\n");
print("OS\n");
print("FH   Key             Location/Qualifiers\n");
print("FH\n");
print("FT   source          1..$total\n");
print("FT                   \/organism=\"\"\n");
print("FT                   \/strain=\"\"\n");

# use Bio::SeqIO to parse through FNA file and grab the CDS translation
my $seqio = Bio::SeqIO->new( '-format' => 'Fasta' , -file => $fna );
my $seqobj = $seqio->next_seq();

# print CDSs first before the final sequence
while(<GLIMMER>){
	if(/>/) { #checks if the character > is in the current line
		#skips the fasta line	
	}	
	else {
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
		
		my $trans; # for /translation tag
		# precondition: we now have the right annotation to use.
		if($end < $start) {
		        print("FT   CDS             complement($end..$start)\n");
			#print("FT                  \/note=\"predicted using Glimmer\"\n");
			#print("FT                  \/gene=\"\"\n");
                        my $dna = $seqobj->subseq($end, $start);
			my $dna_obj = Bio::Seq->new(-seq => $dna);	
			$trans = $dna_obj->revcom->translate(-codontable_id => $transl_table, # Bacterial codon table
                                                                          -complete => 1        # Translate CDS the way EMBL/GenBank/DDBJ do it, 
                                                                                                # confirms start and terminator codons and no terminators
												# within the coding region. Also converts initial amino acid
												# to Methionine if it's non-ATG
                                                                          -throw => 1	        # Die if improper CDS after it checks above since -complete is set to true
									  );
		}
		else {
			print("FT   CDS             $start..$end\n");
			#print("FT                  \/note=\"predicted using Glimmer\"\n");
			#print("FT                  \/gene=\"\"\n");
			my $dna  = $seqobj->subseq($start, $end);
			my $dna_obj = Bio::Seq->new(-seq => $dna);
			$trans = $dna_obj->translate(-codontable_id => $transl_table, # Bacterial codon table
									  -complete => 1	# Translate CDS the way EMBL/GenBank/DDBJ do it, 
												# confirms start and terminator codons and no terminators 
												# within the coding region. Also converts initial amino acid 
												# to Methionine if it's non-ATG
									  -throw => 1   # Die if improper CDS after it checks above since -complete is set to true
									  );
		}		
		#print("FT                   \/product=\"$currAnn[3]\"\n");
		#print("FT                   \/gene=\"$gene\"\n");
		
		# added to remove 'Cluster: ' clause in note
		$currAnn[4] =~ s/Cluster: //g;
		# Grab the first part of the Description field before "n=#", this will be the product name.
		my $nPos = index($currAnn[4], 'n=');
		my $product = "";
		if ($nPos<0) {
			$product = $currAnn[4];
		}
		else {
			$product = substr($currAnn[4], 0, $nPos-1);
		}
		# Another removal of a substring from the first occurrenct of '[' (e.g. [Enterobacteria phage T4]....)
		$nPos = index($product, '[');
		if ($nPos>1) {
			$product = substr($product, 0, $nPos-1);
		} 
	
		print("FT                   \/product=\"$product\"\n");
		print("FT                   \/gene=\"$gene\"\n");
		print("FT                   \/transl_table=$transl_table\n");
		print("FT                   \/note=\"\"\n");

		# Print translation obtaied above
		my $prot = $trans->seq;
		print("FT                   \/translation=\"$prot\"\n");
	}	
}

# close the Glimmer and AutoFACT files
close(GLIMMER);
close(AUTOFACT);

print "XX\n";
print "SQ   Sequence " . $total . " BP; " . $ade . " A; " . $cty . " C; " . $gua . " G; " . $thy . " T; " . $oth . " other;\n"; # print the SQ line
print $seq; # print the sequence in finish of the EMBL file
}
