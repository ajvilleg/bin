#!/bin/csh

#Mac OSx
#grep -lr "/Applications/BIOINFORMATICS/AutoFACT/bitscore.jpg" contig* | xargs perl -p -i -e 's/\/Applications\/BIOINFORMATICS\/AutoFACT\/bitscore.jpg/http:\/\/www\.ncbi\.nlm\.nih\.gov\/blast\/images\/score\.gif/g'
#Supposed to be for rita but it's wrong
#grep -lr "http://www.ncbi.nlm.nih.gov/blast/images/score.gif" contig* | xargs perl -p -i -e 's/\/software\/packages\/AutoFACT\/bitscore.jpg/http:\/\/www\.ncbi\.nlm\.nih\.gov\/blast\/images\/score\.gif/g'
find . | xargs grep -l "/opt/AutoFACT/bitscore.jpg" | xargs perl -p -i -e 's/\/opt\/AutoFACT\/bitscore.jpg/http:\/\/www\.ncbi\.nlm\.nih\.gov\/blast\/images\/score\.gif/g'
