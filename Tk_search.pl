#! /usr/bin/perl 

## Program Info:
#
# Name: Tk_search
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
# 2  Dec 03: v1.4  - Filter out zero hits
# 10 Mar 04: v1.52 - Don't expand degenerate bases switch for proteins
#                  - Search reverse strand only switch, if needed
# 12 Mar 04: 1.6   - Made an option to rank order of hits, clean up logic
# 20 Mar 04: 1.7   - Input searches from a file of strings (-i parameter)
#                  - Strings now input with command line parameter (-s)
# 21 Mar 04: 2.0   - Option to output results as total searches for 
#    each substring summed - no matter what the individual sequences contain
#    (merged in Tsearch code)
#                  - Option to send output as fasta
#    (merged in search2fasta code)
#
# 22 Mar 04: 2.1   - Fixed small output bug
# 23 Mar 04: 2.2   - Fixed "search has to be upper case" bug
#
# 25 Jul 04: 3.0   - Tk version
#
# 12 Aug 04: 3.1   - "filter_zero_hits" to "list_zero_hits" and 
#    concomitant reversal of logic
#                  - Added start fresh button
#                  - Blanks in string file are tolerated
#                  - Reset resets to DNA mode
#
# 28 Feb 05: 4.0   - Calculate and display "expected values" of strings
#                    as an option
#
# 02 Mar 05: 4.1   - Fixed a bug in the Sort results function
#                    as an option
# 03 Mar 05: 4.2   - Fixed a bug in the expected (totals) function
# 13 Jun 05: 4.3   - Cosmetic beautification
#
# 22 Jul 05: 4.4   - Fuzzy search, part 1: allow one mismatch
# 28 Jul 05: 4.5   - Minor bug fix, when search string is cleared
#                  - Fix displayed output of strings
#                  - Cleaned up a lot of the search string processing code
#
#

use warnings;
use strict;

# Modules used:
use IO::File;
use File::Basename;
use Text::Wrap;

# Tk specific:
use Tk 800.000;
use Tk::Dialog;
use Tk::ROText;

## Init variables:
my $title = "Tk_search";
my $version = '4.5';
my $date = '28 July, 2005';
my $author = 'Author: John Nash (john.nash@nrc-cnrc.gc.ca)';
my $copyright = 'Copyright (c) National Research Council of Canada, 2005';
$Text::Wrap::columns = 73;

my $orig_status_message = "version $version - released: $date";
my $status_message = $orig_status_message;

## Program defaults (if you change these, change them in the
#  program restart subroutine too):

my $in_file = '';
my $save_file;

# file of search strings
my $search_file;
# string to be searched - after all processing
my $search_str;
# what is seen in the entry window
my $display_str;

# original string as entered
my @orig_search_str;
# string as processed (interpolated)
my @interpol_str;

my $strands = "both"; # both forward reverse
my $coordinates = "no";
my $list_zero_hits = "no";
my $degeneracies = "yes";    
my $rank = "gene";
my $list_as_fasta = "no";
my $total = "no";
my $cb_value = "DNA mode";
my $expected = "no";
my $fuzzy = "no";

## create the Main Window and assign its attributes:
my $mw = MainWindow->new;
$mw->title($title);
$mw->geometry("+100+100");

### Create and define some fonts:
my $fontsize = 13;
my $font = $fontsize * 10;
my $title_font = $font + 40;
my $fontface = "Courier";
my $FONT = '-*-'.$fontface.'-Medium-R-Normal--*-'.$font.'-*-*-*-*-*-*';
my $BOLDFONT = '-*-'.$fontface.'-Bold-R-Normal--*-'.$font.'-*-*-*-*-*-*';
my $ITALICFONT = '-*-'.$fontface.'-Medium-I-Normal--*-'.$font.'-*-*-*-*-*-*';
my $TITLEFONT = '-*-'.$fontface.'-Bold-R-Normal--*-'.$title_font.'-*-*-*-*-*-*';

## Design notes:
# The Main Window will have three Frames:
# 1. Menubar 
# 2. File Window
# 3. Search string
# 4. Middle text window
# 5. Status window

## Frame 1: No 'expand' necessary
# create the top menubar:
my $menu = $mw->Menu();
$mw->configure(-menu => $menu,
	       -takefocus => 1);

# Menu buttons:
my $file = $menu->cascade(-tearoff => 0,
			  -label => '~File');
my $options = $menu->cascade(-tearoff => 0, 
			     -label => '~Options');
my $help = $menu->cascade(-tearoff => 0, 
			  -label => '~Help');

# file_menuitems:
$file->command(-label => "Start fresh",
	       -accelerator => "Ctl+N", -command => \&restart);
$file->command(-label => "File to search",
	       -accelerator => "Ctl+O", 
	       -command => [ \&get_file, \$in_file ]);
$file->command(-label => "File of search strings",
	       -accelerator => "Ctl+E", 
	       -command => [ \&get_file, \$search_file ]);
$file->separator;
$file->command(-label => "Save results", 
	       -accelerator => "Ctl+S", -command => \&save_data);
$file->separator;
$file->command(-label => "Exit", -accelerator => "Ctl+Q", 
	       -command => [ sub { exit } ]); 

# Bind the keys:
$mw->bind("<Control-n>" => \&restart); 
$mw->bind("<Control-N>" => \&restart); 
$mw->bind("<Control-o>" => [ \&get_file, \$in_file]);
$mw->bind("<Control-O>" => [ \&get_file, \$in_file]);
$mw->bind("<Control-e>" => [ \&get_file, \$search_file]);
$mw->bind("<Control-E>" => [ \&get_file, \$search_file]);
$mw->bind("<Control-s>" => \&save_data);
$mw->bind("<Control-S>" => \&save_data);
$mw->bind("<Control-q>" => [ sub { exit } ]); 
$mw->bind("<Control-Q>" => [ sub { exit } ]); 

# Options menu:
my $op1 = $options->cascade(-label => 'Strand to search', -tearoff => 0);
foreach (qw/both forward reverse/) {
  $op1->radiobutton(
		    -label    => "$_",
		    -variable => \$strands,
		    -value    => $_,
		   );
}

$options->checkbutton(-onvalue => 'yes',
		      -offvalue => 'no',
		      -label => "Expansion of degenerate codons?",
		      -variable => \$degeneracies);

$options->checkbutton(-onvalue => 'yes',
		      -offvalue => 'no',
		      -label => "Show co-ordinates of hits?",
		      -variable => \$coordinates);

my $op2 = $options->cascade(-label => 'Order the results by', -tearoff => 0);
foreach (qw/gene hits/) {
  $op2->radiobutton(
		    -label    => "$_",
		    -variable => \$rank,
		    -value    => $_,
		   );
}

$options->checkbutton(-onvalue => 'yes',
		      -offvalue => 'no',
		      -label => "Show sequences with zero hits?",
		      -variable => \$list_zero_hits);

$options->checkbutton(-onvalue => 'yes',
		      -offvalue => 'no',
		      -label => "List output in fasta format?",
		      -variable => \$list_as_fasta);

$options->checkbutton(-onvalue => 'yes',
		      -offvalue => 'no',
		      -label => "List total hits per subsequence?",
		      -variable => \$total);

$options->checkbutton(-onvalue => 'yes',
		      -offvalue => 'no',
		      -label => "Show expected hits?",
		      -variable => \$expected);

$options->checkbutton(-onvalue => 'yes',
		      -offvalue => 'no',
		      -label => "Allow fuzzy search?",
		      -variable => \$fuzzy);

$options->separator;
$options->command(-label => "Preferences",
		  -accelerator => "Ctl+W", 
		  -command => [\&preferences, $mw ]);

# Bind the keys:
$mw->bind("<Control-w>" => [\&preferences, $mw ]);
$mw->bind("<Control-W>" => [\&preferences, $mw ]);

# help menu: has Instructions and an About box:
# text for the "About" box:
my $about = 
  $mw->Dialog(-title => 'About',
	      -bitmap=> 'info',
	      -default_button => 'OK',
	      -buttons => ['OK'],
	      -font => $FONT,
	      -text => "$title v $version\n".
	      "released: $date\n\n$author\n\n$copyright\n"
	     );

$help->command(-label => "Instructions",
	       -accelerator => "F1",
	       -command => [ \&instructions,$mw ] ); 
$help->command(-label => "About",
	       -command =>[$about=>'Show'] ); 

# Bind the keys:
$mw->bind("<F1>" =>  [ \&instructions,$mw ] ); 


## Frame 2:
my $frame2 = $mw->Frame(-relief => 'groove',
		    -borderwidth => 2 );
$frame2->pack(-side => 'top',
	      -anchor => 'w',
	      -expand => 0,
	      -fill => 'x');

$frame2->Button(-text => "Start fresh",
				   -justify => 'left',
				   -command => [ \&restart ]
				  )->pack(-expand => 0,
					  -fill => 'none',
					  -side => 'left',
					  -anchor => 'w');

my $stringselect_b = $frame2->Button(-text => "File of strings",
				     -justify => 'left',
				     -command => [ \&get_file, \$search_file ]
				    )->pack(-expand => 0,
					    -fill => 'none',
					    -side => 'left',
					    -anchor => 'w');

my $fileselect_b = $frame2->Button(-text => "File to search:",
				   -justify => 'left',
				   -command => [ \&get_file, \$in_file ]
				  )->pack(-expand => 0,
					  -fill => 'none',
					  -side => 'left',
					  -anchor => 'w');

my $file_box = $frame2->Entry(-width => 48,
			      -background => 'white',
			      -textvariable => \$in_file);

$file_box->pack(-expand => 1, 
		-side => 'left',
		-anchor => 'w', 
		-fill => 'x');

$frame2->Label(-textvariable => \$cb_value,
	       -width => 15
	      )->pack(-side => 'right',
		      -anchor => 'e');

my $dna_b = $frame2->Button(-text => "DNA",
			    -command => sub {
			      $cb_value = "DNA mode";
			      $strands = "both";
			      $degeneracies = "yes";
			    })->pack(-side => 'right',
				     -anchor => 'e');

my $protein_b = $frame2->Button(-text => "Protein",
				-command => sub {
				  $cb_value = "Protein mode";
				  $strands = "forward";
				  $degeneracies = "no";
				  $expected = "no";
				})->pack(-side => 'right',
					 -anchor => 'e');


# Show status messages when the buttons are moused over:
$fileselect_b->bind
  ("<Enter>", 
   sub { 
     $status_message 
       = "Selects the file to search "; 
   });
$fileselect_b->bind("<Leave>", sub { $status_message = $orig_status_message });

$dna_b->bind
  ("<Enter>", 
   sub { 
     $status_message 
       = "Sets Strand to \"both\" and Degeneracies to \"yes\" "; 
   });
$dna_b->bind("<Leave>", sub { $status_message = $orig_status_message });

$protein_b->bind
  ("<Enter>", 
   sub { 
     $status_message 
       = "Sets Strand to \"forward\" and Degeneracies to \"no\" "; 
   });
$protein_b->bind("<Leave>", sub { $status_message = $orig_status_message });


## Frame 3:
my $frame3 = $mw->Frame(-relief => 'groove',
			-borderwidth => 2 );

$frame3->pack(-side => 'top',
	      -anchor => 'w',
	      -expand => 0,
	      -fill => 'x');

$frame3->Label(-text => "Search for:",
	       -justify => 'left')->
  pack(-expand => 0,
       -fill => 'none',
       -side => 'left',
       -anchor => 'w');

my $search_box = $frame3->Entry(-width => 80,
				-background => 'white',
				-textvariable => \$display_str);
$search_box->pack(-expand => 1,
		  -side => 'left',
		  -anchor => 'w',
		  -fill => 'x');

my $run_b = $frame3->Button(-relief => 'raised',
			    -text => 'Search',
			    -foreground => '#00cc00',
			    -command => [ sub {
					    $search_str = $display_str;
					    &do_runrun ($mw);
					  }
					   ]
					)->pack(-side => 'right');

my $clear_b = $frame3->Button(-relief => 'raised',
			      -text => 'Clear',
			      -foreground => '#0000cc',
			      -command => [ sub {
					      $display_str = '';
					      $search_file = '';
					    }]
			     )->pack(-side => 'right');


$run_b->bind
  ("<Enter>", 
   sub { 
     $status_message 
       = "Press to initiate the search"; 
   });
$run_b->bind("<Leave>", sub { $status_message = $orig_status_message });

$clear_b->bind
  ("<Enter>", 
   sub { 
     $status_message 
       = "Press to clear the search string"; 
   });
$clear_b->bind("<Leave>", sub { $status_message = $orig_status_message });

$search_box->bind
  ("<Enter>", 
   sub { 
     $status_message 
       = "Enter search string in the box"; 
   });
$search_box->bind("<Leave>", sub { $status_message = $orig_status_message });

## Frame 4:
# This is the part which fills in the main screen. It is where information
#   and results go.

my $frame4 = $mw->Frame(-relief => 'groove',
		    -borderwidth => 2 );

$frame4->pack(-side => 'top',
	      -expand => 1,
	      -fill => 'both');
my $message;
my $maintext = $frame4->Scrolled('ROText',
				 -background => 'white',
				 -scrollbars => 'e',
				 -wrap => 'word',
				 -font => $FONT,
				 -width => 60,
				 -height => 30,
				)->pack (-expand => 1,
					 -fill => 'both',
					);

## All print and printf statements will go to the Main Window:
tie *STDOUT, 'Tk::Text', $maintext;
$maintext->tagConfigure('title', -font => $TITLEFONT);
$maintext->tagConfigure('bold', -font => $BOLDFONT);

$maintext->delete("1.0", 'end');
$maintext->insert ('end', "$title v $version \n", 'title');
$maintext->insert ('end', "\nProgram description\n", 'bold');

print "\nThis program searches nucleotide or protein sequences for a ",
  "pattern or motif and tells you whether it is there or not. It can ",
  "also provide the co-ordinates of each hit.\n";

$maintext->insert ('end', "\nQuick instructions\n", 'bold');

print 
  "\n1. Select a sequence file by pressing the \"File to Search\" button\n";
print "2. Enter a search term or (optionally) a file of terms\n";
print "3. Press the \"Search\" button\n";
print "4. Save the results (Press \"Ctl+S\")\n";

$maintext->insert ('end', "\nFor detailed Instructions\n", 'bold');

print "\nSelect \"Help \| Instructions\" or press <F1>\n";

$maintext->insert ('end', "\nHot keys\n", 'bold');

print "\nFrom the File menu: \n",    
  "  Start Fresh - Ctl+N\n",
  "  Select File to search - Ctl+O\n",
  "  Select File of Search strings - Ctl+E\n",
  "  Save data - Ctl+S\n",
  "  Exit program - Ctl+Q\n\n",
  "Change Preferences - Ctl+W or use the Options menu";

$maintext->see('end');


## Frame 5:
# Status bar:
my $frame5 = $mw->Frame(-relief => 'groove',
			-borderwidth => 2
		       )->pack(-side => 'bottom',
			       -before => $frame4,
			       -expand => 0,
			       -fill => 'x');

my $status_label = $frame5->Label(-textvariable => \$status_message,
				  -justify => 'left',
				 )->pack(-side => 'left');

my $exit_b = $frame5->Button(-relief => 'raised',
			     -text => ' Exit ',
			     -foreground => '#cc0000',
			     -command => sub { exit } 
			    )->pack(-side => 'right');


$exit_b->bind
  ("<Enter>", 
   sub { 
     $status_message 
       = "Press to leave the $title program ";
   });
$exit_b->bind("<Leave>", sub { $status_message = $orig_status_message });

MainLoop;
exit;
# end of main:


#################################################
# Opens a window to capture and change variables:
sub preferences {
# Incoming is: 1. MainWindow object:

# Make the window, etc:
  my $mw = shift;

# Save the old states:
  my $strands_state = $strands;
  my $coordinates_state = $coordinates;
  my $list_zero_hits_state = $list_zero_hits; 
  my $degeneracies_state = $degeneracies;
  my $rank_state = $rank;
  my $total_state = $total;
  my $list_as_fasta_state = $list_as_fasta;
  my $expected_state = $expected;
  my $fuzzy_state = $fuzzy;

# Draw the window etc:  
  my $tl = $mw->Toplevel(-title => "Preferences");
  $tl->resizable(0,0);

# Put it in a frame cos it's prettier:
  my $pf1 = $tl->Frame(-borderwidth => 2,
		       -relief => 'groove');
  $pf1->pack();
  
  my $pf2 = $pf1->Frame()->pack(-side => 'top',
				-padx => 10,
				-pady => 2,
				-anchor => 'w');

# Strand to be searched:
  $pf2->Label(-justify => 'left',
	      -text => 'Select the strand to be searched:',
	     )->pack(-side => 'top',
		     -anchor => 'w');
  
  $pf2->Radiobutton(-justify => 'left',
		    -text => 'Both',
		    -value => 'both',
		    -variable => \$strands
		   )->pack(-side => 'left',
			   -padx => 10,
			   -anchor => 'w');
  
  $pf2->Radiobutton(-justify => 'left',
		    -text => 'Forward',
		    -value => 'forward',
		    -variable => \$strands
		   )->pack(-side => 'left',
			   -padx => 10,
			   -anchor => 'w');
  
  $pf2->Radiobutton(-justify => 'left',
		    -text => 'Reverse',
		    -value => 'reverse',
		    -variable => \$strands 
		   )->pack(-side => 'left',
			   -padx => 10,
			   -anchor => 'w');
  
# Expand degenerate primers - No for protein:
  $pf1->Checkbutton(-onvalue => 'yes',
		    -offvalue => 'no',
		    -justify => 'left',
		    -text => "Expansion of degenerate codons?",
		    -variable => \$degeneracies,
		   )->pack(-side => 'top',
			   -padx => 10,
			   -pady => 2,
			   -anchor => 'w');

# Show co-ordinates of the hits:
  $pf1->Checkbutton(-onvalue => 'yes',
		    -offvalue => 'no',
		    -justify => 'left',
		    -text => "Show co-ordinates of hits?",
		    -variable => \$coordinates,
		   )->pack(-side => 'top',
			   -padx => 10,
			   -pady => 2,
			   -anchor => 'w');
  
# Display hits based on gene order or number of hits:
  my $pf3 = $pf1->Frame()->pack(-side => 'top',
				-padx => 10,
				-pady => 2,
				-anchor => 'w');
  
  $pf3->Label(-justify => 'left',
	      -text => 'Order the results by ',
	     )->pack(-side => 'left',
		     -anchor => 'w');
  
  $pf3->Radiobutton(-justify => 'left',
		    -text => 'Gene',
		    -value => 'gene',
		    -variable => \$rank
		   )->pack(-side => 'left',
			   -padx => 10,
			   -anchor => 'w');
  
  $pf3->Radiobutton(-justify => 'left',
		    -text => 'Hits',
		    -value => 'hits',
		    -variable => \$rank
		   )->pack(-side => 'left',
			   -padx => 10,
			   -anchor => 'w');

# Show zero hits:  
  $pf1->Checkbutton(-onvalue => 'yes',
		    -offvalue => 'no',
		    -justify => 'left',
		    -text => "Show sequences with zero hits?",
		    -variable => \$list_zero_hits,
		   )->pack(-side => 'top',	
			   -padx => 10,
			   -pady => 2,
			   -anchor => 'w');

# List as fasta files or not:
  $pf1->Checkbutton(-onvalue => 'yes',
		    -offvalue => 'no',
		    -justify => 'left',
		    -text => "List output in fasta format?",
		    -variable => \$list_as_fasta,
		   )->pack(-side => 'top',
			   -anchor => 'w',
			   -padx => 10,
			   -pady => 2);
  
# List total hits per substring:
  $pf1->Checkbutton(-onvalue => 'yes',
		    -offvalue => 'no',
		    -justify => 'left',
		    -text => "List total hits per subsequence?",
		    -variable => \$total,
		   )->pack(-side => 'top',
			   -anchor => 'w',
			   -padx => 10,
			   -pady => 2);

# List total hits per substring:
  $pf1->Checkbutton(-onvalue => 'yes',
		    -offvalue => 'no',
		    -justify => 'left',
		    -text => "Show expected hits?",
		    -variable => \$expected,
		   )->pack(-side => 'top',
			   -anchor => 'w',
			   -padx => 10,
			   -pady => 2);

# Allow fuzzy search:
  $pf1->Checkbutton(-onvalue => 'yes',
		    -offvalue => 'no',
		    -justify => 'left',
		    -text => "Allow fuzzy search?",
		    -variable => \$fuzzy,
		   )->pack(-side => 'top',
			   -anchor => 'w',
			   -padx => 10,
			   -pady => 2);

  my $orig_status_message = $status_message;
  
# Buttons:
  my $pf4 = $pf1->Frame()->pack(-side => 'top',
				-pady => 2,
				-anchor => 'e');
  my $ok_b = $pf4->Button(-relief => 'raised',
			  -text => ' OK ',
			  -command => sub { 
			    $status_message = $orig_status_message;
			    $tl->destroy();
			  }
			 )->pack(-side => 'right',
				 -anchor => 'e',
				 -padx => 5);
  
  my $cancel_b = $pf4->Button(-relief => 'raised',
			      -text => ' Cancel ',
			      -command => sub { 
# Bailing? Restore old state:
				$strands = $strands_state;
				$coordinates = $coordinates_state;
				$list_zero_hits = $list_zero_hits_state; 
				$degeneracies = $degeneracies_state;
				$rank = $rank_state;
				$total = $total_state;
				$list_as_fasta = $list_as_fasta_state;
				$expected = $expected_state;
				$fuzzy = $fuzzy_state;
				$status_message = $orig_status_message;
				$tl->destroy();
			      }
			     )->pack(-side => 'right',
				     -anchor => 'e',
				     -padx => 5);

# Show status messages when the buttons are moused over:
  $cancel_b->bind("<Enter>", 
		  sub { 
		    $status_message 
		      = "Press Cancel to back Out... changes will not be made" 
		    });
  $cancel_b->bind("<Leave>", sub { $status_message = $orig_status_message });
  
  $ok_b->bind("<Enter>", 
	      sub { 
		$status_message 
		  = "Press OK to accept changes" 
		});
  $ok_b->bind("<Leave>", sub { $status_message = $orig_status_message });
  
} # end of do_entry


##############################################################
# save_file saves the file using the filename in the entry box
sub save_data {
  $save_file = $mw->getSaveFile(-title => "Save Data");
  return if (!$save_file);
  $status_message = "Saving $save_file";
  open (FH, ">$save_file");
  print FH $maintext->get("1.0", "end");
  $status_message = "Saved!";
} # end of save_data

##############################################################
# Gets and opens a file:
sub get_file {
  my $value = shift;
  $$value = $mw->getOpenFile(-title => "Select a File");

# Show the end of the file box:
  $file_box->xview('end');

} # end of get_file


#################################################################
## Checks all the user-suppled parameters before running the prog:
sub check_parameters {

  my $error_msg = '';
  my $error_flag = 0;


  if (!$in_file) {
    $error_msg = "Please supply a file to search!\n";    
    $error_flag = 1;
}
  
  if (!open (INFILE, $in_file)) {
    $error_msg = "Invalid sequence file!\n";
    $error_flag = 1;
  }
  
# search file parameter:
  if ($search_file) {
    if (! open (SEARCH_FILE, $search_file)) {
      $error_msg =  "Invalid file!\n";
      $error_flag = 1;
    }
  } 
  
# Handle search string logic:
  if (!$search_str and !$search_file) {
    $error_msg = 
      "You must enter a search string or a file of search strings\n";
    $error_flag = 1;
  }

# OK - scream or not if there are error messages - or not:
  unless ($error_msg eq '') {
    my $button = 
      $mw->messageBox('-icon' => 'error', -type => 'Ok',
		      -title => 'Invalid Parameter entered',
		      -message => $error_msg);
  }
  return $error_flag;

} # end of check_parameters


####################
sub restart {
  $in_file = '';
  $search_file = '';
  $search_str = '';
  $display_str = '';
  @orig_search_str = @interpol_str = ();
  $strands = "both";
  $coordinates = "no";
  $list_zero_hits = "no";
  $degeneracies = "yes";
  $rank = "gene";
  $total = "no";
  $list_as_fasta = "no";
  $cb_value = "DNA mode";
  $expected = "no";
  $fuzzy = "no";

  $status_message = $orig_status_message;
  $frame5->update;
  
  $maintext->delete("1.0", 'end');
  $maintext->insert ('end', "$title v $version \n", 'title');
  $maintext->insert ('end', "\nProgram description\n", 'bold');
  
  print "\nThis program searches nucleotide or protein sequences for a ";
  print "pattern or motif and tells you whether it is there or not. It can ";
  print "also provide the co-ordinhates of each hit.\n\n";
  
  $maintext->insert ('end', "\nFor detailed Instructions\n", 'bold');

  print "\nSelect \"Help \| Instructions\" or press <F1>\n\n";
  
  $maintext->insert ('end', "\nHot keys\n", 'bold');
  
  print "\nFrom the File menu:- \n";
  print "     Start Fresh - Ctl+N\n";
  print "     Select File to search - Ctl+O\n";
  print "     Select File of Search strings - Ctl+E\n";
  print "     Save data - Ctl+S\n";
  print "     Exit program - Ctl+Q\n\n";
  print "     Change Preferences - Ctl+W or use the Options menu\n";
  
  $maintext->insert ('end', "\nPress <F1> for help\n", 'bold');
  $maintext->see('end');
  
} # end of restart


################################
## Help/Instructions menu_window:
sub instructions {

  my $mw = shift;
  my $tl = $mw->Toplevel(-title => 'Instructions');
  $tl->geometry("800x600");

  my $text_str;

  my $text = $tl->Scrolled('ROText',
			   -background => 'white',
			   -scrollbars => 'oe',
			   -wrap => 'word',
			   -width => 60,
			   -height => 30,
			   -font => $FONT,
			  )->pack (-expand => 1,
				   -fill => 'both',
				  );

  my $close_b = $tl->Button(-relief => 'raised',
			    -text => ' Close ',
			    -command => sub {
			      $tl->destroy();
			    }
			   )->pack(-side => 'bottom',
				   -anchor => 's');
  
  $text->tagConfigure('title', -font => $TITLEFONT );
  $text->tagConfigure('bold', -font => $BOLDFONT );
  $text->tagConfigure('italic', -font => $ITALICFONT );
  
  $text->insert ('end', "$title v $version Instructions\n", 'title');
  $text->insert ('end', "\n$author\n$copyright\n");

  $text->insert ('end', "\nProgram:  ", 'bold');

  $text_str = "This program searches nucleotide or protein sequences
  for a pattern or motif and tells you whether it is there or not. It
  can also provide the co-ordinates of each hit. It does more... keep
  reading..."; 
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nFile to search:  ", 'bold');

  $text_str = "The sequences to be searched must be in a file on the
  computer from which the search is being run. Clicking the \"File\"
  button on the menubar (or pressing \"Ctl+O\", or pressing the
  \"File to Search\" button) will bring up a Browse box to allow the
  disks to be navigated and the file to be uploaded. The input
  sequence must be in fasta format, which is a universally-accepted
  format for manipulating DNA or protein sequences. Multiple entries
  are supported. No attempt is made to ensure that the input file is a
  valid fasta file. The current active file can be seen in its own
  Entry box, and this entry can be edited by hand";

  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nA note on speed:  ", 'bold');

  $text_str = "When analysing all occurrences of a search string in a
  full genome, expect the program to take time to do it.  It tries to
  be fast but patience is required";

  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nSearch string:  ", 'bold');

  $text_str = "A single sequence snip (called a \"search string\"), or
  a file of strings can be used to search the sequence file. The
  search string can be entered in its own search box located under
  the File Entry box.  Next to the search box, there is a button to
  \"Clear\" the box, and another button to initiate the \"Search\".";

  $text->insert ('end', &munge_txt ($text_str) );
  $text->insert ('end', "\n\n");

  $text_str = "The search string can be a Perl-style regular
  expression. IUB degenerate codons can be used for nucleotide
  searches. For a small explanation on search strings, scroll to the
  bottom of this window.";
  $text->insert ('end', &munge_txt ($text_str) );
  $text->insert ('end', "\n\n");

  $text_str = "A file of strings may be searched. These strings should
  be in a text file, one per line, with no blank lines or comments in
  the file. Fasta files are not appropriate, unless there is a demand
  for this.  Clicking the \"File\" button on the menubar (or pressing
  \"Ctl+E\"), or pressing the \"File of Strings\" button, will bring
  up a Browse box to allow the disks to be navigated and the file of
  search strings to be uploaded. If a search string and a file of
  strings are submitted simultaneously, the string has precedence.";
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nSelect the strand to be searched:  ", 'bold');

  $text_str = "The submitted strand, its reverse-complement or both
  strands of a sequence can be searched, so that nucleotides or
  proteins can be searched appropriately. The program can search a
  computationally-derived reverse-complement of a protein sequence,
  but why (???) would you even want to try that!";
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nOPTIONS\n\n", 'bold');

  $text_str = "Options can be selected from the \"Options\" menu on
  the Menubar, or by pressing \"Ctl+W\". The Options are explained below.";
  $text->insert ('end', &munge_txt ($text_str) );
  $text->insert ('end', "\n\n");

  $text_str = "For ease of use, there are buttons marked \"DNA\" and
  \"Protein\" located next to the File Entry box.  Pressing on the
  appropriate button alters the \"Degeneracies\" and \"Strand to
  Search\" parameters (and only those parameters) depending on whether
  DNA or proteins are being searched, i.e.  to search both strands for
  DNA, and the forward strand for protein, and to allow IUB
  degeneracies for DNA - but not for proteins. A little indicator will
  denote the apppropriate mode.";

  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nExpansion of degenerate codons:  ", 'bold');

  $text_str = "For nucleic acids, degenerate codons can be
  used. These will be expanded, e.g. N to A or C or G, or T. For
  proteins, this is not useful, so deselect this option.";
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nShow co-ordinates of hits:  ", 'bold');

  $text_str = "If co-ordinates of the hits are selected to be
  displayed, they will be based upon the relevant strand
  (i.e. co-ordinate 2 from the reverse strand is the reverse
  complement of the second last base of the forward strand).";
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nOrder the results:  ", 'bold');

  $text_str = "Results can be ranked by order of frequency (hits) or
  by sequence order (gene).";
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nShow sequences with zero hits:  ", 'bold');

  $text_str = "The default is NOT to report sequences which do not
  contain the search string. This option requests that sequence which
  do NOT contain the search string be reported.";

  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nList output in fasta format:  ", 'bold');

  $text_str = "The output can be as a list (default) or in
  fasta format, i.e. one header and search hit per fasta entry. This
  may not be useful at first glance, but combined with regular
  expressions, this can be a powerful motif search tool.";
  
  $text->insert ('end', &munge_txt ($text_str) );
  $text->insert ('end', "\n\n" );

  $text_str = "e.g. Searching N{20}AAGTGCGGTN{20} in the H. influenzae
  genome will find the surrounding 20 bases up-stream and down-stream
  of the Hflu Uptake Signal Sequence (AAGTGCGGT) in that sequence. If
  the \"List as fasta\" option is selected, this output can be fed
  into a multiple sequence alignment program without modification for
  further analysis to looked for conserved motifs surrounding the
  original pattern.  Note that from version 4.0 onwards, the data is
  no longer compressed, i.e. if two or more copies of a result occur,
  each fasta entry is returned.  This will no longer \"compress\" the
  data if generating consensus sequences or Weblogos. ";
  $text->insert ('end', &munge_txt ($text_str) );
  $text->insert ('end', "\n\n");

  $text_str = "It makes no sense to use fasta output with the Show
  coordinates, List Zero hits or Show Total Hits options turned on, so
  when the \"List as fasta\" option is selected, these other options
  are ignored.";
  $text->insert ('end', &munge_txt ($text_str) ); 

  $text->insert ('end', "\n\nList total hits per subsequence:  ", 'bold');

  $text_str = "This will report only the total hits for each
  sub-string, i.e. each member of a search string - assuming that the
  string is degenerate.  This option will not work with the Show
  Co-ordinates, List Zero Hits or List as Fasta options.";
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nShow expected hits:   ", 'bold');

  $text_str = "The expected number of hits to the string to be
  searched can be calculated. This feature is currently only
  implemented for nucleotide strings.  Does it make sense to calculate
  an expected frequency for amino acids?";
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nAllow fuzzy searches:   ", 'bold');

  $text_str = "Fuzzy searching is implemented as a test
  condition. Currently, switching on fuzzy searching causes each
  element in the string to be replaced with a wild-card, so that
  one-offs can be gathered. Eventually, the user will be able to
  control the level of fuzziness for searches.";
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\nNOTE:\n\n", 'bold');

  $text_str = "If both strands are searched, palindromes (such as
  AAGCTT) will be enumerated twice, once per strand. This is a string
  searching program, not a restriction mapping one.";
  $text->insert ('end', &munge_txt ($text_str) );

  $text->insert ('end', "\n\n\nSearch strings\n\n", 'bold');

  $text_str = "Search strings can be much more than Gs, As, Ts and Cs.
  A range of bases or a complex motif can be entered using a
  computational way of expressing complex strings called \"Regular
  expressions\".  Here are some simple short-cuts (make sure
  \"Degeneracies\" are turned OFF).";
  $text->insert ('end', &munge_txt ($text_str) );

  $text_str = '

    Use "."   for any protein
    Use  {x}  for ranges, e.g.:
      N{20}  means a string of 20 Ns
      R{2,5} means 2 to 5 Rs
    Use (N|T) for N or T - note the parentheses, or 
    Use [NT]  for N or T - note the square brackets (alternative)
    Use [^P]  for not P - note the square brackets

    e.g.  "S[^P].{3,5}(A|T)" means:
      1. Find Ser = S
      2. Followed by any amino acid except for Pro = [^P]
      3. Followed by any three to five amino acids = .{3,5}
      4. followed by Ala or Thr = (A|T) or [AT]

';

  $text->insert ('end', $text_str );

}

#############################################################
sub munge_txt {

  my $incoming = shift;
  $incoming =~ s/\n//g;
  $incoming =~ s/ +/ /g;
  return $incoming;
}


###########################################################
## run button - Run the program - the MAJOR code goes here:
sub do_runrun {
  
# Build up some windows and set up some parameters:
  $mw = shift;
  
# Check user-supplied paramaters:
  my $error_flag = &check_parameters();
  return if ($error_flag == 1);

# Clear the screen:
  $maintext->delete("1.0", 'end');
  $status_message = "Working... please wait!";
  $frame5->update;

# call search:
  $maintext->delete("1.0", 'end');
  &run_search();

## Exit routines:
  $maintext->see('1.0');
  $status_message = 
    "Calculations complete: Save your data (use Control-S) !";
  $frame5->update;
  return;
} # end of &do_runrun


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
# Process degeneracies:
sub handle_degeneracies {
# Convert IUB codes to regex values:

  my $incoming = shift;
  if ($incoming =~ m/[RYKMSWHBVDN]/g) {
    $incoming =~ s/R/[AG]/g;
    $incoming =~ s/Y/[CT]/g;
    $incoming =~ s/K/[GT]/g;
    $incoming =~ s/M/[AC]/g;
    $incoming =~ s/S/[CG]/g;
    $incoming =~ s/W/[AT]/g;
    $incoming =~ s/H/[ACT]/g;
    $incoming =~ s/B/[CGT]/g;
    $incoming =~ s/V/[ACG]/g;
    $incoming =~ s/D/[AGT]/g;
    $incoming =~ s/N/[ACGT]/g;
  }
  return $incoming;
} # end of sub handle_degeneracies

#######################################################
sub process_search_string  {

# Processes the search strings:
  my @search_str;
  @orig_search_str = @interpol_str = ();

# string has priority:
# For file has priority, use:
# unless (search_file) { 
  if ($search_str) {

# clears the search_file box:
#    $search_file = '';

# Upper-case from lower, and remove spaces:
    $search_str = uc $search_str;
    $search_str =~ s/ //g;
    $search_str =~ s/\t//g;
    push @orig_search_str, $search_str;
### handle degeneracies:
    $search_str = &handle_degeneracies ($search_str) 
      if ($degeneracies eq "yes");    
    push @search_str, $search_str;
    push @interpol_str, $search_str;
  }

# If we have a search file, clear the search_str scalar 
# and populate it with the file's data:
  else {

# Clears the search string box:
    $display_str = '';
    
# read in each value
    foreach (<SEARCH_FILE>) {
      s/\r\n/\n/g;
      chomp;
      next unless (/\w+/);
      $_ = uc $_;
      push @orig_search_str, $_;
      $_ = &handle_degeneracies ($_) 
	if ($degeneracies eq "yes");    
      push @search_str, "($_)";
      push @interpol_str, "$_";
    }  
    close SEARCH_FILE;
    
### LAZY way: join the whole $search array as an "or-separated" string:
    $search_str = join ("|", @search_str);
  }

# Except for fuzzy searches, search string(s) process is done:
  return $search_str unless ($fuzzy eq "yes");

## The next part fuzzy-izes a search string
  my %made_fuzzy;
  my @tmp;

# randomize one element in the string, across the string
  foreach (@search_str) {
    my $string_size = length $_;
    for my $k (0..$string_size-1) {
      my $new_string = $_;
      my $element = substr($new_string, $k, 1);
      if ($element =~ /[A-Za-z]/) {
	substr($new_string, $k, 1, '.');
      }

# This keeps the strings unique:
      $made_fuzzy{$new_string}++;
    }
  }

# string them out:
  foreach (sort keys %made_fuzzy) {
    push @tmp, "($_)";
    push @interpol_str, "$_";
  }
  $search_str = join ("|", @tmp);

# send back the output:
  return $search_str;
  
} # end of &process_search_string


#######################################################
# Standalone search code: plugged in here:
# Same code and sub used in search 3.0 and up
# No Tk-specific code allowed in here!
# print has been directed to a Tk::Text widget by tieing STDOUT above

sub run_search {
	
### Main run code:
  
# Process the search string:
  $search_str = &process_search_string;

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
      $sigma += $total_hits;

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
    print "Fuzzy search\n" if ($fuzzy eq 'yes');
    my $fn = basename ($in_file);

    unless ($display_str) {
      print "Searching file: \n\t$fn \n";    
      if ($search_file) {
	my $sfn = basename ($search_file);
	print "Search file: \n\t$sfn \n";
      }
    }

# Format the search strings so that complex strings are easy to follow
#   in the output:
    print "Original Search string: \n";
    print "\t$_\n" foreach (@orig_search_str);

    print "Interpolated Search string: \n";
    print "\t$_\n" foreach (@interpol_str);

    print "Total hits for entire search: \n\t$sigma\n";
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
	
# we don't want totals - we want individuals:
  else {
    foreach (@order) {
      my $count = 1;

# If BOTH strands or forward strand is selected, 
#  and we DO have hits in the forward strand:

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
