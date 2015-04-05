#!/usr/bin/perl

# This scripts requires AF2EMBL.pl (convert from AutoFACT to EMBL) and 
# changeNCBIScoreBarLink.csh
# This is the updated script that will do the following:
# 0. Assigns proper permission to all contig folders and files
# 1. convert each contig output to EMBL format
# 2. convert each EMBL file to GBK format
# 3. find the sizes in BP for each contig
# 4. create a JNLP file to be able to view each annotation in Artemis through Java Web Start
# 5. output everything in appropriate order in an index.html file
# 6. changes all the NCBI e-range bars to the proper link.
# 
# USAGE: AutoFACT_IndxHTML

# chmod all folders to rwx--x--x
print "Assigning proper permissions to all folders...\n";
system("find . -type d -print | xargs chmod 0711") && die "Failed: error code = $?\n";
# chmod all files to rw-r--r--
print "Assigning proper permissions to all files...\n";
system("find . -type f -print | xargs chmod 0644") && die "Failed: error code = $?\n";

open(INDEX, ">index.html"); #open for write, overwrite

#print to file in freeform
print INDEX <<ENDHEADER;
<html>
<head>
</head>
<body>
<br>
<h1>Ecoli O83 Contigs AutoFACT Index</h1>
<br>

ENDHEADER

# Find the sizes of the contigs and save into a file to sort later and run the rest of code, outputting in decreasing order
print "Creating seqSizes file...\n";
@files = <contig*>;
open(SIZES, ">seqSizes");
foreach $i (@files) {
	chdir($i);
	open(CURR, "<$i.TXT");
	$fasta = <CURR>; #read the first line of the file, this can be used to read every line too.
	@first = split(' ', $fasta);
	# can also do split(/ +/) for more than one space
	@second = split(/=/, $first[1]);
	print SIZES <<ENDCONTIG;
$second[1] $i
ENDCONTIG
	close(CURR);
	chdir("..");
}
close(SIZES);
#sort the filename in decreasing BP size
system("sort -r -n seqSizes > seqSizes2") && die "Failed: error code = $?\n"; 
rename("seqSizes2", "seqSizes"); #rename the file back to original
# Convert the AutoFACT annotation to EMBL format and convert to GBK format using readseq on Rita.
$pwd = `pwd`;
$numContigs = 0;
$totalSize = 0;
print "Converting annotation to EMBL and GBK...\n";
open(SIZES, "<seqSizes");
while(<SIZES>) {
	$numContigs++;
	@curr = split(/ /, $_);
	$i = $curr[1];
	chomp($i);
	if (-e "$i/$i.orfs.out") { # if the orfs.out file exists, i.e. if there are orfs
		# Convert the AutoFACT annotation to EMBL format
		#system("cd $i") && die "Failed: error code = $?\n";
		chdir($i);
		$pwd = `pwd`;
		print $pwd;
		system("cp /home/villegas/bin/AF2EMBL.pl .") && die "Failed: error code = $?\n";
		system("./AF2EMBL.pl $i.predict $i.orfs.out $i.TXT > $i.embl") && die "Failed: error code = $?\n";
		system("chmod 644 $i.embl") && die "Failed: error code = $?\n";
		# Remove the script from the current directory to cleanup
		system("rm AF2EMBL.pl") && die "Failed: error code = $?\n";

		# create a link to each orfs.html
		#echo '&nbsp;&nbsp;&nbsp;&nbsp;<a href="'$i'/'$i'.orfs.html">'$i'</a>' >> index.html
		print INDEX "&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"$i/$i.orfs.html\">$i</a>\n";
		
		# print the size of the contig in BP
		print INDEX "&nbsp;&nbsp;&nbsp;&nbsp;$curr[0] bp\n";
		$totalSize = $totalSize + $curr[0];
	
		# Convert the EMBL file to a GBK file
		system("readseq -f Genbank -o $i.gbk $i.embl") && die "Failed: error code = $?\n";
		system("chmod 644 $i.gbk") && die "Failed: error code = $?\n";
	
		# Create the JNLP file with the proper arguments the EMBL file to open Artemis.
		open(JNLP, ">$i.jnlp"); # write to jnlp file.
		print JNLP <<ENDJNLP;
		<?xml version="1.0" encoding="UTF-8"?>
		<jnlp
        		spec="1.0+"
	        	codebase="http://www.sanger.ac.uk/Software/Artemis/v10/u3/"
        		href="Artemis.jnlp">
	        	<information>
        		<title>Artemis</title>
	        	<vendor>Sanger Institute</vendor>
        		<homepage href="http://www.sanger.ac.uk/Software/Artemis/"/>
	        	<description>Artemis</description>
	        	<description kind="short">DNA sequence viewer and annotation tool.
	        	</description>
	        	<offline-allowed/>
	        	</information>
	        	<security>        
			   <all-permissions/>
			</security>       
	 		<resources>
			<j2se version="1.4+ 1.4.2" initial-heap-size="32m" max-heap-size="200m"/>
				<jar href="sartemis_v10.3b.jar"/>
	        		<property name="com.apple.mrj.application.apple.menu.about.name" value="Artemis" />
	        		<property name="artemis.environment" value="UNIX" />
	        		<property name="j2ssh" value="" />
	        	</resources>
			<application-desc main-class="uk.ac.sanger.artemis.components.ArtemisMain">
				<argument>http://rita.imb.nrc.ca/~villegas/AnnotationDone/Ecoli_O83_H1_sequencelargecontigsMay2008/$i/$i.embl</argument>
			</application-desc>
       	 	</jnlp>	
ENDJNLP
# the string terminator ENDJNLP above should be unquoted and not surrounded by any whitespace so it'll work

		close(JNLP);

		system("chmod 644 $i.jnlp") && die "Failed: error code = $?\n";
		#system("cd ..") && die "Failed: error code = $?\n";
		chdir("..");
	
		# Create link to the Artemis JNLP
		print INDEX "&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"$i/$i.jnlp\">Artemis View</a>";

		# Create link to download the EMBL and GBK file
		print INDEX "&nbsp;&nbsp;&nbsp;&nbsp;<b>Downloads:</b>\n";
		print INDEX "&nbsp;&nbsp;<a href=\"$i/$i.embl\">$i.embl</a>\n";
		print INDEX "&nbsp;&nbsp;<a href=\"$i/$i.gbk\">$i.gbk</a>\n";

	}
	else {
		# print contig name
		print INDEX "&nbsp;&nbsp;&nbsp;&nbsp;<i>$i</i>\n";
		
		# print the size of the contig in BP
		print INDEX "&nbsp;&nbsp;&nbsp;&nbsp;$curr[0] bp\n";
		
		# print NO ORFS warning
		print INDEX "&nbsp;&nbsp;&nbsp;&nbsp;<b>NO ORFS</b>\n";

	}

	print INDEX "<br>\n";
#end
}
print INDEX "<br><strong>Number of contigs:</strong>&nbsp;$numContigs&nbsp;&nbsp;&nbsp;<strong>Total Size:</strong>&nbsp;$totalSize<br>\n";
close(SIZES);
print INDEX "</body>\n";
print INDEX "</html>\n";
close(INDEX);
system("chmod 644 index.html") && die "Failed: error code = $?\n";

# fix the link to the NCBI score bar
print "Fixing links to NCBI score bar...\n";
system("cp /home/villegas/bin/changeNCBIScoreBarLink.csh .") && die "Failed: error code = $?\n";
system("./changeNCBIScoreBarLink.csh");
unlink("changeNCBIScoreBarLink.csh");

print "DONE.\n"
