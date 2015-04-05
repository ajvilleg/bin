#!/usr/bin/perl -w
#-----------------------------------------------------------+
#                                                           | 
# Blast2Gff.pl                                              |
#                                                           |
#-----------------------------------------------------------+
#  AUTHOR: James C. Estill                                  |
# CONTACT: JamesEstill_at_gmail.com                         |
# STARTED: 04/17/2007                                       |
# UPDATED: 04/18/2007                                       |
# DESCRIPTION:                                              |
#  Converts BLAST output to GFF format. This the the GFF    |
#  format that is used with the Apollo Genome Annotation    |
#  curation program.                                        |
#  Currently this only works with m8 blast output.          |
#                                                           |
#-----------------------------------------------------------+

=head1 INCLDUES
=cut
#-----------------------------+
# INCLUDES                    |
#-----------------------------+
use strict;                   # Keeps thing running clean
use Getopt::Std;              # Get options from command line
use Bio::SeqIO;

=head1 VARIABLES
=cut
#-----------------------------+
# VARIABLES                   |
#-----------------------------+
my $GffAppend;                 # BOOLEAN. Append to GFF file
my $InFile;                    # Full path to the input blast output file
my $OutFile;                   # Full path to the gff formatted output file
my $AlignFormat;               # Alignment format of the blast output file
                               # ie. -m = 0,8, or 9
my $PrintHelp;                 # Boolean, print the Usage statement
my $BlastDb;                   # Blast database 
my $GBK;		       # Blast databse GBK file
my $BlastProg;                 # Blast program (ie. blastn, blastx
my $SeqName;                   # Name of the sequence file used for query

my $Usage = "USAGE:\n".
    "Blast2Gff.pl -i InFile.Fasta -o OutFile.gff -d BlastDb\n".
    " -p blastprogram -m AligFormat -s SeqName -a\n\n".
    " -i Full path to the BLAST output file[STRING]\n".
    " -o Full path for the GFF formated file [STRING]\n".
    "    Default is the intput file path with gff extension.\n".
    " -d Blast database that was blasted against [STRING]\n".
    "    This is required\n".
    " -g Full path to Blast database GBK that was blasted against [STRING]\n".
    " -s ".
    " -m Format of the algnment outout from blast [INTEGER]\n".
    "    Default value is 8. Valid values are 0,8,9".
    " -p Blast program used [STRING]\n".
    "    Default is blastn\n".
    " -a Append results to the gff file [BOOLEAN]\n".
    "    Default is to overwrite any exiting file.\n".
    " -h Print this help statement [BOOLEAN]\n";

=head1 COMMAND LINE VARIABLES
=cut
#-----------------------------+
# COMMAND LINE VARIABLES      |
#-----------------------------+
my %Options;
getopts('d:i:o:m:p:g:s:ha', \%Options);

$PrintHelp = $Options{h};
if ($PrintHelp)
{
    print $Usage;
    exit;
}

$SeqName = $Options{s} ||
    die "\aERROR: A sequence file name must be specified\n$Usage\n";
$GffAppend = $Options{a};
$InFile = $Options{i} ||
    die "\aERROR: An input file must be specified.\n\n$Usage\n";
# Default output is the full path of the input file with the gff extension
$BlastProg = $Options{p} ||
    "blastn";
$BlastDb = $Options{d} || 
    die "\aERROR: A blast database should be indicated.\n\n$Usage\n";
$GBK = $Options{g} ||
    die "\aERROR: The Blast database GBK file should be indicated.\n\n$Usage\n";
$OutFile = $Options{o} ||
    $InFile.".gff";
$AlignFormat = $Options{m} || 
    "8";                        # Default format is tab delim

#-----------------------------+
# CHECK FILE EXISTENCE        |
#-----------------------------+
unless (-e $InFile)
{
    print "The input file could not be found\n$InFile\n";
    exit;
}

#-----------------------------+
# CONVERT BLAST FILE TO GFF   |
#-----------------------------+
# Test Blast2Gff subfunction

if ($AlignFormat == "8")
{
#    &TabBlast2Gff ($InFile, $OutFile, $BlastDb, $SeqName, "blastn"); modified by Andre Aug 31, 2010
	&TabBlast2Gff ($InFile, $OutFile, $BlastDb, $SeqName, $BlastProg);
} else {
    print "A valid BLAST alignment format was not selected.\n";
}


#-----------------------------------------------------------+
# SUBFUNCTIONS                                              |
#-----------------------------------------------------------+

sub TabBlast2Gff 
{
    my $In = $_[0];       # Path to blast intput file
    my $Out = $_[1];      # Path to gff output file
    my $Db = $_[2];       # The BLAST databas the hits are derived from
    my $Name = $_[3];     # Seqname
    my $Prog = $_[4];     # BLAST program used
    my $GStart;           # GFF Start position 
    my $GEnd;             # GFF End position

#    my $Format = $_[4];   # Format of the blast file
#                          # 8,9, 0 etc
#    my $UseScore = $_[5]; # Score format to use
    
    my $HitNum = "0";
    #-----------------------------+
    # FILE I/O                    |
    #-----------------------------+
    open (BLASTIN, "<".$In) ||
	die "Can not open BLAST input file.$In.\n";
    
    # If append was selected, just append gff data to the
    # output file
    if ($GffAppend)
    {
	open (GFFOUT, ">>".$Out) ||
	    die "Can not open GFF ouput file.$Out.\n";
    } else {
	open (GFFOUT, ">".$Out) ||
	    die "Can not open GFF ouput file.$Out.\n";
    }    

	#array of feature objects of the 'gene' tag
    #my @gene_features = grep { $_->primary_tag eq "gene" } Bio::SeqIO->new(-file => $GBK)->next_seq->get_SeqFeatures;
	my $gbk = Bio::SeqIO->new(-file => $GBK);
	my $seq = $gbk->next_seq;
	my %loci = ();
	#my %strand = {}; # the GFF file will not have the right STRAND outputs
	for my $feat_object ($seq->get_SeqFeatures) {
	#foreach my $feat_object (@gene_features) {
		if ($feat_object->primary_tag eq "gene" ) {
			for my $val ($feat_object->get_tag_values('locus_tag')) {
				$loci{$val} = $feat_object->location->start; # in this function, start is always less than end, and the strand attribute tell you if it's 1 or -1
			}
		}
	}

    my $lastQuery = "none";
    while (<BLASTIN>)
    {

	next if (/^\#/ || /^\s*$/); # filter comments and empty lines from http://biostar.stackexchange.com/questions/277/how-to-convert-blast-results-to-gff/286#286

	$HitNum++;
   	
	# Check this: http://biostar.stackexchange.com/questions/277/how-to-convert-blast-results-to-gff/281#281
	my ($QryId, $SubId, $PID, $Len, 
	    $MisMatch, $GapOpen, 
	    $QStart,$QEnd, $SStart, $SEnd,
	    $EVal, $BitScore) = split(/\t/);

	# To get only the top hit for each query, see if the next query was the same as old, if it is, skip it.
	if ($lastQuery eq $QryId) {
		next;
	}
	else {
		$lastQuery = $QryId;
	}
	
	my $Strand; # will be correct in the output
	my $Frame = ".";

	# NOT USING SINCE WE ARE GONNA USE THE REFERENCE Start and End coordinates		
	# Set the start to be less then the end
	# This info can be used to dedeuct the strand
	#if ($QStart < $QEnd)
	#{
	#    $GStart = $QStart;
	#    $GEnd = $QEnd;
	#    $Strand = "+";
	#} elsif ($QStart > $QEnd) {
	#    $GStart = $QStart;
	#    $GEnd = $QEnd;
	#    $Strand = "-";
	#} else {
	#    die "Unexpected Query Start and End:\n\tS:$QStart\n\tE:$QEnd";
	#}

	# REWRITE ABOVE TO USE REFERENCE Start & End
    # Set the start to be less then the end
    # This info can be used to dedeuct the strand
    if ($SStart < $SEnd)
    {
        $GStart = $SStart;
        $GEnd = $SEnd;
        $Strand = "+";
    } elsif ($SStart > $SEnd) {
        #$GStart = $SStart; # this line and the line below is kind of WRONG,  should switch
        #$GEnd = $SEnd;	   # the start and end to make start < end, and then set strand to '-'
						   # also wrong in the commented area above. Commenting it, rewriting below...
		$GStart = $SEnd;
		$GEnd = $SStart;
        $Strand = "-";
    } 
	else {
        die "Unexpected Query Start and End:\n\tS:$QStart\n\tE:$QEnd";
    }

	# Calculate actual locations on the subject genome by using the gene start coordinates from GBK file.
	$GStart = $loci{$SubId} + $GStart - 1;
	$GEnd = $GStart + $Len - 1;
		
	# Trim leading white space from Bit score
	$BitScore =~ s/^\s*(.*?)\s*$/$1/;
	
	# Currently working with this to get it to draw
	# the items as separate items
	print GFFOUT 
	    # I initially used the following
#	    $Name."\t".   # SeqName
	    $SubId."\t".
#	    $Prog.":".$Db."\t".    # Source (BLAST PROGRAM)
		$QryId."\t".		   # Query ID
#	    $Prog.":".$Db."\t".    # Feature (Database)
#	    $SubId."\t".           # Feature (Database)
#	    $Prog."\t".            # Feature (Database)
		$EVal."\t".			   # E-value
	    $GStart."\t".          # Start
	    $GEnd."\t".            # End
#	    $BitScore."\t".        # Score
		$PID."\t".			   # Percent Identity
	    $Strand."\t".          # Strand
	    $Frame."\t".           # Frame
#	    $SubId.                # Attribute
		$Len.				   # Alignment length
	    "\n";
	
    } # END OF WHILE BLASTIN
	close(GFFOUT);
	close(BLASTIN);
    
} # END OF Blast2Gff Subfunction


#-----------------------------------------------------------+
# PROGRAM STARTED
#-----------------------------------------------------------+
# 04/17/2007
# - Program started
# - Started Blast2Gff subfunction with tab delim format
# 
# 04/18/2007
# - Adding command line options
# - Working on Blast2Gff tab delim format
