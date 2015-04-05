#!/bin/csh

#Loop through all files
#For each file, make a folder, move the file into the folder
#run Glimmer on it.
cd ..
foreach i ( *.fas )
	set name = `echo $i | sed 's/.fas//'`
	echo $name
	mkdir $name
	mv $i $name/
	cd $name/
	pwd
	../scripts/circular-g3-iterated.csh $i $name
	extract $i $name.predict > $name.orfs
	cd ..
end
