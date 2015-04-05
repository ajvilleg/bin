#!/usr/bin/perl

use strict;

my $TODAY = time;
my $DIR = $ARGV[0];
my $wktime = 432000; # (ie 86400*5) 86400 seconds in a day, 5 days
###############################################################################
sub remove_old_dir {
     open (LOGFILE, ">./recentlyDeleted.log");
     opendir DIR, $DIR or die "could not open directory: $!";
     while (my $file = readdir DIR) {
     	next if -f "$DIR/$file"; # skip if it's a file, not a directory
     	my $mtime = (stat "$DIR/$file")[9];
     	if ($TODAY - $wktime > $mtime) {
		print LOGFILE "$DIR/$file is older than 7 days...removing\n";
     		#unlink $file;
     	}
     }
     close LOGFILE;
     close DIR;
}
################################################################################
sub remove_old_dirs {
	open (LOGFILE, ">$DIR/recentlyDeleted.log");
	foreach (glob("$DIR/*")) {
		#print $_;
		my $age = -M;
		if ($age > 5) {
			print LOGFILE "$_ is over 5 days old...DELETED.\n";
			system("rm -rf $_") && die "rm -rf $_ failed: error code = $?\n";
		} else {
			#print "$_ is " . int($age) . " days old\n";
		}
	}
	close LOGFILE;
}
################################################################################
Main:
{
     #remove_old_dir(); #this version is bullshit, the one below is better.
     remove_old_dirs();
}
