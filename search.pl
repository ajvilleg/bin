#! /usr/bin/perl

## Program Info:
#
# Name: search
#
# Purpose: Searches both strands of a FASTA file for a search 
#   string, and returns the co-ordinates of each hit.  The search
#   string can be a regular expression.  IUB degenerate codons
#   can be used for nucleotide searches. It will do one or both
#   strands of a DNA sequence.
#
# Author: John Nash
#
# Copyright (c) National Research Council of Canada, 2003-2004,
#   all rights reserved.
#
# Licence: This script may be used freely as long as no fee is charged 
#   for use, and as long as the author/copyright attributions 
#   are not removed. It remains the property of the copyright holder.
#
# History:
# 17 Jul 02:       - Initial version, adapted from restrict
# 18 Jul 02: v1.2  - regex length bug fixed
# 3  Nov 03: v1.3  - Added total counts
# 2  Dec 03: v1.4  - Filter out zero hits (-O)
# 10 Mar 04: v1.52 - Don't expand degenerate bases switch (-P) for proteins
#                  - Search reverse strand only switch (-R), if needed
# 12 Mar 04: 1.6   - Switch (-S) to rank order of hits, clean up logic
# 20 Mar 04: 1.7   - Input searches from a file of strings (-i parameter)
#                  - Strings now input with command line parameter (-s)
# 21 Mar 04: 2.0   - Switch (-T) to output results as total searches for 
#    each substring summed - no matter what the individual sequences contain
#    (merged in Tsearch code)
#
#                  - Switch (-L) to send output as fasta
#    (merged in search2fasta code)
#
# 22 Mar 04: 2.1   - Fixed small output bug
# 23 Mar 04: 2.2   - Fixed "search has to be upper case" bug
#
# 24 July 04: 3.0  - Code made compatible with Tk_search - couple of 
#                    switch changes made
# 12 Aug 04: 3.1   - "filter_zero_hits" to "list_zero_hits" and
#                    concomitant reversal of logic
#                  - Added start fresh button
#                  - Blanks in string file are tolerated
#                  - Reset resets to DNA mode
#
# 28 Feb 05: 4.0   - Calculate and display "expected values" of strings
#                    as an option
# 02 Mar 05: 4.1   - Fixed a bug in the Sort results function
# 03 Mar 05: 4.2   - Fixed bug in expected (totals) function
#
##

use warnings;
use strict;
use Text::Wrap;
use File::Basename;

# Init variables:
my $title = "search";
my $version = "4.2";
my $date = "3 Mar, 2005";
my $error_msg = "Type \"$title -h\" for help.";
$Text::Wrap::columns = 73;

# Get and process the command line params:
# Returns array of $fasta_file and $orf_file;
my $in_file;
my ($search_str, $search_file, $strands, $coordinates, 
    $list_zero_hits, $degeneracies, $rank, $total,
    $list_as_fasta, $expected) = process_command_line();

## Handle search string logic:
if ($search_str eq '' and $search_file eq '') {
  die("\n", 
      "Error: You must enter a search string or a file of search strings\n",
      $error_msg, "\n");
}

if ($search_file ne '') {
# open the search file
  open (SEARCH_FILE, $search_file) or 
    die ("\nError: Cannot open file $search_file: $!\n",
	 $error_msg, "\n");
}

## Handle input parameters:
## Does the input sequence exist:  handle errors
# If $ARGV[0] is not blank, test for file's existence:
if (defined $ARGV[0]) {
  unless (-e $ARGV[0]) {
    die("\nError: Sequence file \'$ARGV[0]\' does *not* exist. \n", 
				$error_msg, "\n");
  }
  $in_file = $ARGV[0];
}

open (INFILE, $in_file) or 
  die ("\nError: Cannot open file $in_file: $!\n",
       $error_msg, "\n");


### Run the search --> same sub as in Tk_search:
&run_search();


## end of main()


############################################################################
sub help {
print <<EOHelp;
$title $version (released $date)

  $title searches nucleotide or protein sequences for a pattern or motif 
  and tells you whether it is there or not. It can also provide the 
  co-ordinates of each hit. It does more... keep reading...

Syntax:  $title -s \"search_string\" \"file_name\"
         $title -i \"file of search strings\" \"file_name\"
         $title -option \"-s search_string\" \"file_name\"
         $title -option \"-i file of search strings\" \"file_name\"
           where  -C -E -F -L -O -P -R -S or -T are optional switches

  or     $title -h for help


Input file:  The file being searched must be in FASTA format, which is a common
  sequence format used by most bioinformatics software.  No attempt is made 
  to ensure that the input file is a valid FASTA file.  The program will 
  accept a FASTA file containing multiple sequences and report the 
  co-ordinates from each sequence.  


Search strings:  Search strings can be much more than Gs, As, Ts and Cs.
  A range of bases or a complex motif can be entered using a
  computational way of expressing complex strings called \"Regular
  expressions\".  Here are some simple short-cuts (make sure
  \"Degeneracies\" are turned OFF i.e. use -P):

    - Use "." for any protein

    - Use  {x}  for ranges, e.g.:
        - N{20} means a string of 20 Ns
        - R{2,5} means 2 to 5 Rs

    - Use (N|T) for N or T - note the brackets

    - Use [^P] for not P - note the square brackets

    e.g.  "S[^P].{3,5}(A|T)" means:

      1. Find Ser = S
      2. Followed by any amino acid except for Pro = [^P]
      3. Followed by any 3 to five amino acids = .{3,5}
      4. followed by Ala or Thr = (A|T)


Compulsory parameters (either -s or -i must be used - but not both): 
   -s    to specify a search string.  Perl-style reqular expressions are
         accepted.

   -i    to specify a file of strings.  There must be one string per line
         separated by a carriage return.


Switches (use a switch to get the option, leave it out for the default):
   -C    will return the co-ordinates of each hit.
         (The default is that $title doesn\'t return co-ordinates, 
          just the number of hits)

   -E    will calculate the expected number of hits to the string to be 
         searched. This feature is currently only implemented for 
         nucleotide strings.  Does it make sense to calculate an 
         expected frequency for amino acids?
         (The default is that $title does not display expected values)

   -F    will search just the sequence in the FASTA file, and not its 
         complement - so proteins can be searched. 
         (The default is that $title searches both strands)

   -R    will search just the reverse-complemented strand of a sequence
         so that individual strands of DNA can be searched.
         (The default is that $title doesn\'t do this)

   NOTE: Don't select both "\-F\" and \"-R\". You won't get both strands 
         searched, just one of them - likely at random. If you want both 
         strands searched, leave both switches out.

   -L    will return the search in fasta format.  This may not be useful at 
         first glance, but combined with regular expressions, this can be a 
         powerful motif search tool:

         e.g. \'search -Ls \"N{20}ACAAGCGGTN{20}\" app_genome.fasta\'

         will find the surrounding 20 bases up- and down-stream of the App
         Uptake Signal Sequence (ACAAGCGGT}) in the file \'app_genome.fasta\'.
         It makes no sense to use this with the \"-C\", \"-O\", \"-S\" or
         \"-T\" switches.  Note that from version 4.0 onwards, the data is 
         no longer compressed, i.e. if two or more copies of a result occur, 
         each fasta entry is returned.  This will no longer \"compress\" 
         the data if generating consensus sequences or Weblogos.
         (The default is that $title does not return data in fasta format)

   -O    will return the sequences which have zero hits.
         (The default is that $title filters out names of sequences with 
          zero hits)

   -P    will NOT translate degenerate codons into their individual 
         counterparts. Useful for searching proteins or regular expressions.
         (The default is that $title translates degenerate codons, 
          e.g. N = A or C or G or T)

   -S    will sort the multiple sequences in the order of most hits to a 
         search_string to least hits.
         (The default is that $title ranks hits in order of genes presented)

   -T    will report only the total hits for each sub-string, i.e.
         each member of a search string - assuming that the string is 
         degenerate.  This won\'t recognize the \"-C\", \"-O\" or \"-S\" 
         switches, but will work with the \"-F\", \"-P\" and \"-R\" switches.
         This switch replaces my program \"Tsearch\", and merges it into this
         codestream.  (default - $title doesn\'t do this)

Co-ordinates are based upon the relevant strand (i.e. co-ordinate 
   2 from the reverse strand is the reverse complement of the second 
   last base of the forward strand).  

NOTE: Palindromes (such as AAGCTT) will be enumerated twice, once per 
   strand.  This is a string searching program, not a restriction mapping 
   one. 

If this scrolls by too fast type: \"$title \| more\".
EOHelp
die ("\n");
} # end of sub help


##################################################################
sub process_command_line {
# Variables:
  my %opts = ();    # command line params, as entered by user
  my @cmd_line;     # returned value
  my @list;         # %opts as an array for handling
  my $cmd_args;	    # return value for getopts()
  my $item;
  
# Holders for command line parameters:
  my $search_str = '';
  my $search_file = '';
  my $strands = "both";  # both, reverse, forward
  my $coordinates = "no";
  my $list_zero_hits = "no";
  my $degeneracies = "yes";    
  my $rank = "genes"; # or hits
  my $total = "no";
  my $list_as_fasta = "no";
	my $expected = "no";

# Get the command=line parameters:
  use vars qw($opt_s $opt_i $opt_h 
							$opt_C $opt_E $opt_F $opt_L $opt_O $opt_P $opt_R 
							$opt_S $opt_T);
  use Getopt::Std;
  $cmd_args = getopts('s:i:hCEFLOPRST', \%opts);
  
# Die on illegal argument list:
  if ($cmd_args == 0) {
    die ("Error: Missing or incorrect command line parameter(s)!\n",
				 $error_msg, "\n");
  }
  
# Make the hashes into an array:
  @list = keys %opts;
  
# Do a quick check for "help" and the compulsory parameters:
  foreach $item (@list)  {
# Help:
    if ($item eq "h")  {
      help();
    }
# Do we want co-ordinates:
    elsif ($item eq "C") {
      $coordinates = "yes";
    }
# Do we want expected hits to a string calculated?
    elsif ($item eq "E") {
      $expected = "yes";
    }
# Search both strands?:
    elsif ($item eq "F") {
      $strands = "forward";
    }
# List output as FASTA?:
    elsif ($item eq "L") {
      $list_as_fasta = "yes";
    }
# Do we want filter out zero hits cos they are a pain:
    elsif ($item eq "O") {
      $list_zero_hits = "yes";
    }
# Do we want degeneracies:
    elsif ($item eq "P") {
      $degeneracies = "no";
    }
# Do we want only reverse strand searched:
    elsif ($item eq "R") {
      $strands = "reverse";
    }
# Do we want output ranked by most hits:
    elsif ($item eq "S") {
      $rank = "hits";
    }
# Do we want totals (Tsearch):
    elsif ($item eq "T") {
      $total = "yes";
    }
# Demi-compulsory parameter (search string):
    elsif ($item eq "s") {
	    $search_str = $opts{$item};
	  }
# Demi-compulsory parameter (file of search strings):
    elsif ($item eq "i") {
      $search_file = $opts{$item};
    }
  }
  
# Put it in an array:
  @cmd_line = ($search_str, $search_file, $strands, $coordinates, 
							 $list_zero_hits, $degeneracies, $rank, $total,
							 $list_as_fasta, $expected);
  return @cmd_line;
	
} #end of sub process_command_line()


##############################################################
sub searchit {
# Expects:
# 1. search string
# 2. sequence to be searched
# Returns a list of references to:
#  %hits containing $hit -> ref to array of coords

  my $search_str = $_[0];
  my $sequence = $_[1];
  my (%hits, $hit, $coord_ref);
  my $coord;
  
  while ($sequence =~ /(?=($search_str))/g) {
    $hit = substr($sequence, pos $sequence, (length $1));
    $coord = (pos $sequence) + 1;
    push @{$hits{$hit}}, $coord;
  }
  return %hits;
} # end of searchit


#######################################################
sub calc_expected {
# Calculates the expected number of hits to a string:
# Expects:
# 1. search string
# 2. sequence to be searched
# Returns the theoretical (expected) number of hits to that string
#  accounting for TGCA content
	
  my $incoming = $_[0];
  my $sequence = $_[1];
	my $exp_hits;
	my $percent_bases;
	my ($As, $Cs, $Gs, $Ts, $totalACGT, 
			$iAs, $iCs, $iGs, $iTs, 
			$fractA, $fractC, $fractG, $fractT);

# Calculating ACGT content of BIG sequence:
# Ignore non GATC at the moment.  Handle N or . or - later, if needed.
	$As = ($sequence =~ tr/A//);
	$Cs = ($sequence =~ tr/C//);
	$Gs = ($sequence =~ tr/G//);
	$Ts = ($sequence =~ tr/T//);
	$totalACGT = $As + $Cs + $Gs + $Ts;

# Convert to 2 decimal places:
	$fractA = sprintf("%0.2f", $As/$totalACGT);
	$fractC = sprintf("%0.2f", $Cs/$totalACGT);
	$fractG = sprintf("%0.2f", $Gs/$totalACGT);
	$fractT = sprintf("%0.2f", $Ts/$totalACGT);
	
# Calculate #ACGTs of smaller string:
	$iAs = ($incoming =~ tr/A//);
	$iCs = ($incoming =~ tr/C//);
	$iGs = ($incoming =~ tr/G//);
	$iTs = ($incoming =~ tr/T//);
	
# Calculate expected hits:
	$percent_bases = ($fractA**$iAs) * ($fractC**$iCs) * 		
		($fractG**$iGs) * ($fractT**$iTs);
	$exp_hits = $percent_bases * length $sequence;
	
# Expected hits reporting:
	if ($exp_hits > 10000) { 
		$exp_hits = sprintf ("%0.1e", $exp_hits);
	}
	elsif ($exp_hits < 0.1)  { 
		$exp_hits = sprintf ("%0.1e", $exp_hits);
	}
	else {
		$exp_hits = sprintf ("%0.1f", $exp_hits);
	}

	return $exp_hits;
}


#######################################################
# Standalone search code: plugged in here:
# Same code and sub used in search 3.0 and up

sub run_search {
	
### Main run code:
  
# Populate @search_str;
  my @search_str;
  $search_str = uc $search_str unless ($search_file);
  
# If we have a search file, clear the search_str scalar 
# (string has priority over file) and populate it with the file\'s data:
  if ($search_file) {
		
# Probably redundant:
    $search_str = '';
    
    # read in each value
    foreach (<SEARCH_FILE>) {
      s/\r\n/\n/g;
      chomp;
      next unless (/\w+/);
      $_ = uc $_;
      push @search_str, "($_)";
    }
		
### LAZY way: join the whole $search array as an "or-separated" string
    $search_str = join ("|", @search_str);
    $search_str = "$search_str";
  }
  close SEARCH_FILE;
  
	
## Read in the sequence from a multiple FASTA file:
# holds $sequence_name->$sequence_string
  my %sequence;
  my $seq_name;
	
# Holds the input order used in %sequence.  Tieing the hash is 
#  far more elegant, but cramming the variables in an array index
#  knocks 20% off execution time
  my @order;
	
# read in the sequence from a FASTA file:
  foreach (<INFILE>) {
		
# Substitutes DOS textfile carriage returns with Unix ones:
    s/\r\n/\n/g;
    chomp;
    if (/^>/)  {  
      $_ = substr($_, 1, length $_);
			
# remove training spaces from name:
      s/ $//g;
      $seq_name = $_;
      push @order, $seq_name; 
    }
    else {
      $sequence{$seq_name} .= uc $_;
    }
  }
  close INFILE;
	
## Process search string:
  my $search_len = length $search_str;
  my $orig_search_str = $search_str;
	
  if ($degeneracies eq "yes") {
# Convert IUB codes to regex values:
    if ($search_str =~ m/[RYKMSWHBVDN]/g) {
      $search_str =~ s/R/[AG]/g;
      $search_str =~ s/Y/[CT]/g;
      $search_str =~ s/K/[GT]/g;
      $search_str =~ s/M/[AC]/g;
      $search_str =~ s/S/[CG]/g;
      $search_str =~ s/W/[AT]/g;
      $search_str =~ s/H/[ACT]/g;
      $search_str =~ s/B/[CGT]/g;
      $search_str =~ s/V/[ACG]/g;
      $search_str =~ s/D/[AGT]/g;
      $search_str =~ s/N/[ACGT]/g;
    }
  }
  
## Handle the string search:
# holds $sequence_name->$total hits forward / reverse / total
  my (%sequence_regexF, %sequence_regexR, %sequence_regexT); 
	
# holds $sequence_name->reference to hash of $substring->@hit_coords
  my (%sequence_hitsF, %sequence_hitsR);
  
# grand total hits
  my $sigma;

# expected (if needed)
# hit->expected number;
	my %exp_hits_f;
	my %exp_hits_r;
	my %exp_hits_T;

  foreach (keys %sequence) {
    my $target = $sequence{$_};
		
# Send off the FORWARD sequence to be searched
    if ($strands ne "reverse") {
      my $total_hits = 0;
      my %hits = ();
      %hits = searchit ($search_str, $target);
      $sequence_hitsF{$_} = \%hits;
			
# Count the number of times each sequence is hit by the search string
      foreach my $hit (keys %hits) {
				$total_hits += scalar @{$hits{$hit}};
      }
      $sequence_regexF{$_} = $total_hits;
      $sequence_regexT{$_} = $total_hits;
      $sigma +=	 $total_hits;

# Count the expected number of hits:
			if ($expected eq "yes") {
				foreach my $hit (keys %hits) {
					$exp_hits_f{$hit} = calc_expected ($hit, $target);
					$exp_hits_T{$hit} += $exp_hits_f{$hit};
				}
			}
		} # end of if ($strands ne "reverse")

		
# Send off the REVERSE sequence to be searched
    if ($strands ne "forward") {
      my $total_hits = 0;
      $target = reverse $target;
      ($target =~ tr/XNATGCBDKRVHMYSW[]/XNTACGVHMYBDKRWS][/);
      my %hits = ();
      %hits = searchit ($search_str, $target);
      $sequence_hitsR{$_} = \%hits;
			
# Count the number of times each sequence is hit by the search string
      foreach my $hit (keys %hits) {
				$total_hits += scalar @{$hits{$hit}};
      }
      $sequence_regexR{$_} = $total_hits;
      $sequence_regexT{$_} += $total_hits;
      $sequence_regexF{$_} = 0 unless (exists $sequence_regexF{$_});
      $sigma += $total_hits;

# Count the expected number of hits:
			if ($expected eq "yes") {
				foreach my $hit (keys %hits) {
					$exp_hits_r{$hit} = calc_expected ($hit, $target);
					$exp_hits_T{$hit} += $exp_hits_r{$hit};
				}
			}
		}    # end of if ($strands ne "forward") 
	} # end of foreach (keys %sequence) 
	
# Rank by "hits" was selected:
  if ($rank eq "hits") {
    @order = ();
    foreach (sort { $sequence_regexT{$b} <=> $sequence_regexT{$a} } 
						 keys %sequence_regexT) {
      push @order, $_;
    }
  }
	
## Display results
  if ($list_as_fasta eq "no") {
		
# Print the initial status message:
    my $fn = basename ($in_file);
    print "Searching file: $fn \n";
    
    if ($search_file) {
      my $sfn = basename ($search_file);
      print "Search file: $sfn \n";
    }
		
    print wrap '', '', "Original Search string: $orig_search_str\n";
    print wrap '', '', "Interpolated search string: $search_str\n";
    print "Total hits for entire search: $sigma\n";
  }
	
	
## If we are just interested in the total hits for each substring:
  if ($total eq "yes") {
    my %total;
    
## count the total hits:
# Forward hits:
    if ($strands ne "reverse") {
      foreach (keys %sequence_hitsF) {
				my $matches = $sequence_hitsF{$_};
				foreach my $hit (keys %{$matches}) {
					$total{$hit} += scalar @{${$matches}{$hit}};
				}
      }
    }
		
# Reverse strand:
    if ($strands ne "forward") {
      foreach (keys %sequence_hitsR) {
				my $matches = $sequence_hitsR{$_};
				foreach my $hit (keys %{$matches}) {
					$total{$hit} += scalar @{${$matches}{$hit}};
				}
      }
    }
		
# and print the outcomes:
    foreach (sort keys %total) {
      print "$_ ($total{$_} hits";
			print "; ", 
			(exists $exp_hits_T{$_} ? $exp_hits_T{$_} : 0), " exp" 
				if ($expected eq "yes");
			print ")\n";
    }
  }
	
## we don't want totals - we want individuals:
  else {
    foreach (@order) {
      my $count = 1;
## If BOTH strands or forward strand is selected, and we DO have hits
#   in the forward strand:
# Print total hits:
      if ($strands ne "reverse") {
				if (($list_zero_hits eq "yes") or 
						($list_zero_hits eq "no" and $sequence_regexF{$_} > 0)) {
					
					if ($list_as_fasta eq "no") {
						print wrap '','', "\n$_\n";
						print "Total hits: $sequence_regexT{$_}\n";
					}
				}
				
# Print the hits for each sequence and each substring found:
				if ($sequence_regexF{$_} > 0 or $list_zero_hits eq "yes") {
					if ($list_as_fasta eq "no") {
						print "Forward strand: $sequence_regexF{$_} hits\n";
					}
					
					my $matches = $sequence_hitsF{$_};
					foreach my $hit (keys %{$matches}) {
						if ($list_as_fasta eq "no") {
							print "  $hit (", scalar @{${$matches}{$hit}}, " hits";
							print "; ", 
							(exists $exp_hits_f{$hit} ? $exp_hits_f{$hit} : 0), " exp" 
							if ($expected eq "yes");
							print ")\n";							
						}
						else {
							foreach my $count (1..scalar @{${$matches}{$hit}}) {
								print "\>$_.", $count, " F\n$hit\n";
							}
						}
						
# If co-ordinates are wanted, print them:
						if ($coordinates eq "yes" and $list_as_fasta eq "no") {
							print "  Co-ordinates:\n";
							my $coords = join ("\t", @{${$matches}{$hit}});
							print wrap("\t", "\t", "$coords");
							print "\n";
							
						}
					}
				}
			} # end of ($strands ne "reverse")
			
## If we have BOTH strands selected and no hits in the forward strand:
#   OR if we just want the reverse strand searched:
#      if ($strands eq "both") {
      if ($strands ne "forward") {
				if (($list_zero_hits eq "yes" and $sequence_regexR{$_} == 0
						 and $strands eq "reverse") or
						($list_zero_hits eq "no" 
						 and $sequence_regexF{$_} == 0 
						 and $sequence_regexR{$_} > 0) 
						or ($strands eq "reverse" and $sequence_regexR{$_} > 0)) {
					if ($list_as_fasta eq "no") {
						print wrap '', '', "\n$_\n";
						print "Total hits: $sequence_regexT{$_}\n";
					}
				}
				
# Print the hits for each sequence and each substring found:    
				if ($sequence_regexR{$_} > 0 or $list_zero_hits eq "yes") {
					if ($list_as_fasta eq "no") {
						print "Reverse strand: $sequence_regexR{$_} hits\n"
						}
					
					my $matches = $sequence_hitsR{$_};
					foreach my $hit (keys %{$matches}) {
						if ($list_as_fasta eq "no") {
							print "  $hit (", scalar @{${$matches}{$hit}}, " hits";
							print "; ", 
							(exists $exp_hits_r{$hit} ? $exp_hits_r{$hit} : 0), " exp" 
								if ($expected eq "yes");
							print ")\n";
						}
						else {
							foreach my $count (1..scalar @{${$matches}{$hit}}) {
								print "\>$_.", $count, " R\n$hit\n";
							}
						}
# If co-ordinates are wanted, print them: 	    
						if ($coordinates eq "yes" and $list_as_fasta eq "no") {
							print "  Co-ordinates:\n";
							my $coords = join ("\t", @{${$matches}{$hit}});
							print wrap("\t", "\t", "$coords");
							print "\n";
						}
					}
				}
      }
    }
  } # end of ($total's else)
} # end of sub run_search

### end of code
