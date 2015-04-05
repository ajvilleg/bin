#!/bin/csh

## Program Info:
#
# Name: modifyFastaLines
#
# Rationale: The Glimmer ORFfinder, labels each orf as "orf#####", so if you have a genome with multiple contigs
#	     chances are you'll have orf00001 for each contig, i.e. there's orf00001 for both contig A and contig B

# Function: This script will rename each orf in a multifasta file of orfs by adding the contig name to the beginning of
#	    of the fasta line right after the '>'. This will insure uniqueness when concatenating all the orfs from all
#	    the contigs together for BLASTing or reverse hybs.
#
# Usage: run beside all the contigs multiOrf files.
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2008-2009
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.

foreach i ( *.orfs )
	set name = `echo $i  | sed 's/.orfs//'`
	echo $name
	sed 's/>/>'$name'/g' $i > $name.f.orfs
end
