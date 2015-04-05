<?php
/* Program Info:

   Name: <Name of Program>.php

   Function: This php script reads a CSV file with headings and tries to load into a nonexistent table OR an empty but existing 	    table in a MySQL database.

   Author: Andre Villegas

   Copyright (c) Public Health Agency of Canada, 20XX-20XX
   All Rights Reserved.

   Licence: This script may be used freely as long as no fee is charged
      for use, and as long as the author/copyright attributions
      are not removed. It remains the property of the copyright holder.

   History:
*/
# PHP getopt info: http://php.net/manual/en/function.getopt.php
# getopt code below is from: http://www.php.net/manual/en/function.getopt.php#79047
$opts = getopt('i:o:');
// Handle command line arguments
foreach (array_keys($opts) as $opt) switch ($opt) {
	case 'i':
		// Do something with i parameter
		$input = $opts['i'];
		break;
	
	case 'o';
		//Do something with o parameter
		$output = $opts['o'];
		break;
}

if !(isset($input) && isset($output)) {
	echo <<<END
<Name of Program>.php	This tool does a lot of bullshit.

Usage:	[option]
	-i Path to input
	-o Path to output

Example:
php <Name of Program>.php -i inputfile -o outputfile
	END;
exit(1);
}

<?php

$conn = mysql_connect('localhost','xxxxxxxx','xxxxxxxx');

mysql_select_db('mapdatabase');

mysql_query("TRUNCATE TABLE mytable") or die(mysql_error());

mysql_query("LOAD DATA LOCAL INFILE 'importfile.csv'
INTO TABLE mytable
Fields terminated by ',' ENCLOSED BY '\"'
LINES terminated by '\n'(
name
,address
,fruit
,lat
,lng)")

or die("Import Error: " . mysql_error());
?>

?>
