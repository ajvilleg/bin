#!/usr/bin/perl

#print "\n******************************************************************";
#print "\n*    gbk2ffn.pl                                             	 *";
#print "\n*    Created by PK June 3,2008 for use at LFZ               	 *";
#print "\n*    Convert a genbank file to (multi)fasta formatted nucleotide *";
#print "\n*    (.ffn) and associated feature table (.xls)		         *";
#print "\n*    Modified Sept 16, 2009 to account for files without locustag        *";
#print "\n******************************************************************";
#print "\n";

use strict;
use warnings;
use Bio::SeqIO;
use Bio::DB::GenBank;
use Bio::SeqFeature::Generic;
use Bio::PrimarySeqI;

my $usage = "gbk2ffn.pl infile\n";
my $infile = shift or die $usage;

my $len = -4;
my $fastaOut = substr($infile,0,$len)."-fasta.ffn";
my $outFile = substr($infile,0,$len)."-features.xls";
my $multifasta = '';
my $fasta_header = '';
my $ftable = '';
my $ftb = '';
my $ftableheader = '';
my $source = '';
my @cds_features = '';
my $accession = '';

my @GenBankFile=();
############################################################################
# Get the GenBank data into an array from a file, and find source organism
############################################################################
	@GenBankFile=get_file_data($infile);

	# Extract the source name
	foreach my $line (@GenBankFile) {
		if($line =~ /^SOURCE/) {
			$line =~ s/^SOURCE\s*//;
			$source=$line;
			chop($source);
		}
	}

	# Extract the accession
	foreach my $line (@GenBankFile) {
		if($line =~ /^ACCESSION/) {
			$line =~ s/^ACCESSION\s*//;
			$accession=$line;
			chop($accession);
			#print "Accession: " ,$accession,"\n";
		}
	}


#print "Converting genbank file of ", $source, " ..\n";

my $seqin = Bio::SeqIO->new(	'-file' => "<$infile",
				'-format' => 'Genbank');

############################################################################
# Go through genbank file and extract information (feature table, multifasta)
############################################################################

while (my $seq = $seqin->next_seq) {
  my $id = $source."\t0..".$seq->length."\n";
  #print $id, "\n";
  #print "=================================================================\n"; 
  #print "========================= Feature Table =========================\n";  
  #print "=================================================================\n"; 
  my $header = "Location\tStrand\tLength\tGene\tLocusTag\tProduct\tNotes\n";
  #print $header;
  #print "=================================================================\n"; 

  for my $feat_object ($seq->get_SeqFeatures) {
	my $ftype = $feat_object->primary_tag;
 		if ($ftype eq 'CDS') {

############
#Sequence:
############

	#@cds_features = grep { $_->primary_tag eq 'CDS' } $feat_object;
	#my %gene_sequences = map {$_->get_tag_values('gene'), $_->spliced_seq->seq } @cds_features;
	#my @fastaseq = %gene_sequences;

	my @fastaseq = '';
	@fastaseq= $feat_object->spliced_seq->seq;	

      #	print "Fasta sequence is: ",$fastaseq[0],"\n";	


############
# Location:
############
	my $location = $feat_object->location;
	my $loc = $location->start."..".$location->end."\t";

############
# Strand:
############
	my $strand = $feat_object->strand;
	$strand =~ s/-1/-/;	
	$strand =~ s/1/+/;

############
# Length:
############
	my $length = $location->end - $location->start + 1;

############
# Gene:
############
	my @geneinfo='';
	my $isGeneinfo=0;
	$isGeneinfo = $feat_object->has_tag('gene');
	if ($isGeneinfo) {
		@geneinfo = $feat_object->get_tag_values('gene'); 
	}
	else {
		@geneinfo="\t";
	}
	#print "GeneInfo: ",$geneinfo[0],"\n";
	#print "GeneInfo present? ",$isGeneinfo,"\n";

############
# Locus Tag:
############
	my @locustag='';
	my $islocustag=0;
	$islocustag = $feat_object->has_tag('locus_tag');
	if ($islocustag) {
		@locustag = $feat_object->get_tag_values('locus_tag'); 
	}
	else {
		@locustag="\t";
	}

############
# Product:
############
	my @productinfo='';
	my $isproductinfo=0;
	$isproductinfo = $feat_object->has_tag('product');
	if ($isproductinfo) {
		@productinfo = $feat_object->get_tag_values('product'); 
	}
	else {
		@productinfo="\t";
	}

############
# Notes:
############
	my @noteinfo='';
	my $isnoteinfo=0;
	$isnoteinfo = $feat_object->has_tag('note');
	if ($isnoteinfo) {
		@noteinfo = $feat_object->get_tag_values('note'); 
	}
	else {
		@noteinfo="\t";
		#@noteinfo="\t\t";
	}
	
############
# End (assemble information)
############

	$ftableheader="Coordinates\tStrand\tLength\tGene\tLocus\tProduct\tMiscellaneous\n";		$ftable=$ftable.$loc.$strand."\t".$length."\t".$geneinfo[0]."\t".$locustag[0]."\t".$productinfo[0]."\t".$noteinfo[0]."\n";

##################################################################################
# customize fasta header depending on what information there is for the feature:
##################################################################################
#Create header
if (!$isGeneinfo and $islocustag) {
	if (!$accession eq '') {
		$fasta_header = ">".$accession."|".$locustag[0]."|".$source." from ".$loc."\n";
	}
	else {
		$fasta_header = ">".$locustag[0]."[".$source." from ".$loc."\n";
	}
}
elsif (!$islocustag and $isGeneinfo) {
	if (!$accession eq '') {
		$fasta_header = ">".$accession."|".$geneinfo[0]."|".$source." from ".$loc."\n";
	}
	else {
		$fasta_header = ">".$geneinfo[0]."[".$source." from ".$loc."\n";
	}
}
elsif ($islocustag and $isGeneinfo) {
	if (!$accession eq '') {
		$fasta_header = ">".$accession."|".$locustag[0].":".$geneinfo[0]."|".$source." from ".$loc."\n";
	}
	else {
		$fasta_header = ">".$locustag[0].":".$geneinfo[0]."|".$source." from ".$loc."\n";
	}
}
else {
	$fasta_header = ">".$accession."|".$source." from ".$loc."\n";
}

#Append header to sequence
$multifasta=$multifasta.$fasta_header.$fastaseq[0]."\n";
	

      } #if loop

  } #for loop

$ftb = $ftableheader.$ftable;

############
# write to files
############
	open(FTB,">$outFile");
	print FTB $ftb;
	close FTB;

	open(FAS,">$fastaOut");
	print FAS $multifasta;
	close FAS;
	#return 1;

} #while loop

sub get_file_data{
	
	my ($file)=@_;
	use strict;
	use warnings;

	# Initialize variables
	my @filedata=();
	unless(open(GET_FILE_DATA,$file)) {
		print STDERR "Cannot open file \"$file\"\n\n";
		exit;
	}
	@filedata=<GET_FILE_DATA>;
	close GET_FILE_DATA;
	return @filedata;
}
