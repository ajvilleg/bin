#!/usr/bin/perl

#print "\n**********************************************************";
#print "\n*    gbk2fna.pl , CopyRight @ cail, Fudan University.    *";
#print "\n*    Convert a file in current dir please enter 1,       *";
#print "\n*    Convert all files in current dir please enter 2.    *";
#print "\n*                                                        *";
#print "\n*    !!MODIFIED BY ANDRE VILLEGAS FOR LFZ, PHAC!!        *";
#print "\n**********************************************************\n";
#print "\nPlease enter your choice (1 or 2) : ";
#my $choice=<STDIN>;
#print "\nGOOD LUCK!\n\n";
#chop($choice);

#if($choice==1){
#	print "Please input the ACCESSION ID of the files : ";
#	my $input=<STDIN>;
#	chop($input);
#	my $filename=$input.".gbk";
#	my $output='';
#	$output=$input.".fna";
#	gbk2fna($filename,$output);
#}
#elsif($choice==2){
#	my $dir = ".";
#	opendir(DIR0, $dir) or die "Can't open $dir: $!\n";
#	while (defined(my $filename = readdir(DIR0))) {
#		next unless $filename =~ /\.gbk$/;
#		my $output=substr($filename,0,9).".fna";
#		print "$filename -> $output\n";
#		gbk2fna($filename,$output);
#	}
#}
#else{
#	print "The program does not support this request. SORRY.";
#}

$numArgs = $#ARGV + 1;
if($numArgs>0){
	if($ARGV[0] eq "all"){
		my $dir = ".";
		opendir(DIR0, $dir) or die "Can't open  $dir: $!\n";
		while (defined(my $filename = readdir(DIR0))) {
			next unless $filename =~ /\.gbk$/;
			my $output=substr($filename, 0, length($filename)-4).".fna";
			print "$filename -> $output\n";
			gbk2fna($filename,$output);
		}
	}
	else{
		foreach $argnum (0 .. $#ARGV){
			my $filename = $ARGV[$argnum];
			my $output=substr($filename, 0, length($filename)-4).".fna";
			#print "$filename -> $output\n";
			gbk2fna($filename,$output);
		}
	}
}
else{
	print "Not enough arguments!\n";
	print "Usage: perl gbk2fnaAV.pl [all | *.gbk filename(s)]\n";
	print "	e.g. \"perl gbk2fnaAV.pl all\"\n";
	print "	     \"perl gbk2fnaAV.pl 1.gbk 2.gbk\"\n";
}

exit;
	
sub gbk2fna{

	my ($data,$output)=@_;
	
	my @GenBankFile = (  );
	my $o=''; #organism
	my $d=''; #total sequence
	my $d1=''; #version+accession
	my $d4=''; #nucleic acid sequence
	my $d4t=''; #temp of d4
	my $true=0;
	
	@GenBankFile=get_file_data($data);
    
	foreach my $line (@GenBankFile) {
		if($line=~/^\/\/\n/){
			last;
		}
		elsif($line=~/^DEFINITION/){
			$line=~s/^DEFINITION (.+)\.\n$/$1/g;
			$o=$line;
		}
		elsif($line=~/^VERSION/){
			$line=~s/^VERSION\s+(.+)\s+GI:(.+)\n$/$2|man|$1/g;
			$d1=$line;
			chop($d1);
        }
        elsif($line=~/^ORIGIN/){
        	$true=1;
        }
        elsif($true==1){
        	$d4t.=$line;
        }
    }
    
    $d4t=~s/[\s0-9]//g;
	$d4=uc($d4t);
	
	#$d=">cl|".$d1."|".$o."\n";
	$d=">cl|".$d1."|".$o; # To remove the extra line after the fasta line

	my $i=0;
	while($i<length($d4)) {
		$d.=substr($d4,$i,70)."\n";
		$i+=70;
	}

    open(FNA,">$output");
	print FNA $d;
	close FNA;
	return 1;
    
}

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
