#!/bin/csh

echo "<html>" > index.html
echo "	<head>" >> index.html
echo "	</head>" >> index.html
echo "	<body>"	>> index.html
echo "<br>" >> index.html
echo "<h1>Ecoli O83 Contigs AutoFACT Index</h1>" >> index.html
echo "<br>" >> index.html
foreach i (contig*)
	# create a link to each orfs.html
	echo '&nbsp;&nbsp;&nbsp;&nbsp;<a href="'$i'/'$i'.orfs.html">'$i'</a>' >> index.html
	
	# Convert the AutoFACT annotation to EMBL format
	cd $i
	cp ~/bin/AF2EMBL.pl .
	./AF2EMBL.pl $i.predict $i.orfs.out $i.TXT > $i.embl
	chmod 644 $i.embl

	# Remove the script from the current directory to cleanup
	rm AF2EMBL.pl
	
	# Convert the EMBL file to a GBK file
	
	
	# Create the JNLP file with the proper arguments the EMBL file to open Artemis.
	echo '<?xml version="1.0" encoding="UTF-8"?>' > $i.jnlp
	echo '<jnlp' >> $i.jnlp
        echo 'spec="1.0+"' >> $i.jnlp
        echo 'codebase="http://www.sanger.ac.uk/Software/Artemis/v10/u3/"' >> $i.jnlp
        echo 'href="Artemis.jnlp">' >> $i.jnlp
        echo ' <information>' >> $i.jnlp
        echo '   <title>Artemis</title>' >> $i.jnlp
        echo '   <vendor>Sanger Institute</vendor>' >> $i.jnlp
        echo '   <homepage href="http://www.sanger.ac.uk/Software/Artemis/"/>' >> $i.jnlp
        echo '   <description>Artemis</description>' >> $i.jnlp
        echo '   <description kind="short">DNA sequence viewer and annotation tool.' >> $i.jnlp
        echo '   </description>' >> $i.jnlp
        echo '   <offline-allowed/>' >> $i.jnlp
        echo ' </information>' >> $i.jnlp
        echo ' <security>' >> $i.jnlp
        echo '   <all-permissions/>' >> $i.jnlp
        echo ' </security>' >> $i.jnlp
        echo ' <resources>' >> $i.jnlp
        echo '   <j2se version="1.4+ 1.4.2" initial-heap-size="32m" max-heap-size="200m"/>' >> $i.jnlp
        echo '     <jar href="sartemis_v10.3b.jar"/>' >> $i.jnlp
        echo '   <property name="com.apple.mrj.application.apple.menu.about.name" value="Artemis" />' >> $i.jnlp
        echo '   <property name="artemis.environment" value="UNIX" />' >> $i.jnlp
        echo '   <property name="j2ssh" value="" />' >> $i.jnlp
        echo ' </resources>' >> $i.jnlp
	echo ' <application-desc main-class="uk.ac.sanger.artemis.components.ArtemisMain">' >> $i.jnlp
	echo '         <argument>http://rita.imb.nrc.ca/~villegas/AnnotationDone/Ecoli_O83_H1_sequencelargecontigsMay2008/'$i'/'$i'.embl</argument>' >> $i.jnlp
	echo '	 </application-desc>' >> $i.jnlp
        echo '</jnlp>' >> $i.jnlp
	chmod 644 $i.jnlp
	cd ..
	
	# Create link to the Artemis JNLP
	echo '&nbsp;&nbsp;&nbsp;&nbsp;<a href="'$i'/'$i'.jnlp">Artemis View</a>' >> index.html

	# Create link to download the EMBL file
	echo '&nbsp;&nbsp;&nbsp;&nbsp;<b>Downloads:</b>' >> index.html
	echo '&nbsp;&nbsp;<a href="'$i'/'$i'.embl">'$i'.embl</a>' >> index.html
	
	echo "<br>" >> index.html
end
echo "	</body>" >> index.html
echo "</html>" >> index.html
chmod 644 index.html
