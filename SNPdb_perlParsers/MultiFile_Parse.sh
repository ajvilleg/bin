#!/bin/bash

for i in ./*.txt; 
do 
echo ${i%.txt};
perl HapMap_FileParser.perl $i $i.parsed.csv

done

echo "\nThe End\n"; 
