<?php
# adapted from: http://www.experts-exchange.com/Web_Development/Web_Languages-Standards/PHP/PHP_Databases/Q_26524262.html
header('content-type:text/plain');
/* Program Info:

   Name: importCSVwithHeadingsToMYSQL.php

   Function: This php script reads a CSV file with headings and tries to load into a nonexistent table OR an empty but existing table in a MySQL database.

   Author: Andre Villegas

   Copyright (c) Public Health Agency of Canada, 20XX-20XX
   All Rights Reserved.

   Licence: This script may be used freely as long as no fee is charged
      for use, and as long as the author/copyright attributions
      are not removed. It remains the property of the copyright holder.

   History:
   18 March 2011	- finished initial version
*/
# PHP getopt info: http://php.net/manual/en/function.getopt.php
# getopt code below is from: http://www.php.net/manual/en/function.getopt.php#79047
$csvfilename = "";
$tablename = "";
$opts = getopt('i:t:');
// Handle command line arguments
foreach (array_keys($opts) as $opt) switch ($opt) {
	case 'i':
		// Do something with i parameter
		$csvfilename = $opts['i'];
		break;
	
	case 't':
		$tablename = $opts['t'];
		break;

}

$dbhost = 'localhost';
$dbuser = 'chms_admin';
$dbpass = 'chms_admin';
$dbname = 'chms';
mysql_connect($dbhost, $dbuser, $dbpass) or die (mysql_error() . " Query: " . $query);
mysql_select_db($dbname) or die  ('Error connecting to ' . $dbname);
mysql_query("TRUNCATE TABLE " . $tablename) or die (mysql_error()); #empties a table completely 
$merror   = mysql_error();
	if (!empty($merror)) {
  	print "MySQL Error:<br />" . $merror;
	};

//$csvfilename = 'UVB_dailymean_CHMS_reformatted.csv';
//$tablename = 'uv';

// Read in the csv data
if(($csvfile = fopen($csvfilename, "r")) !== false)
{
	// Get list of fieldnames from first line of csv
	$fieldlist = fgetcsv($csvfile);

	// Make a table definition
	foreach($fieldlist as $fieldname) $coldefs[] = "`$fieldname` float";

	// Make insert statements
	while(($record = fgetcsv($csvfile))!== false) // Get the next line from the file
	{
		#if($logfield = array_search('Log', $fieldlist)) // Find which index the "Log" column is at
		#{
		#	$tables[$record[$logfield]] = true; // Add the table name to the list of tables
		#	$tablename = $record[$logfield];
		#}
		#else
		#{
		#	$tablename = 'UnnamedLog';
		#}

		$values = array(); // Clear the value list
		foreach($record as $value) $values[] = "'".addslashes($value)."'"; // Build the value list
		$queries[] = "insert into `$tablename` (`".implode('`, `', $fieldlist)."`) values (".implode(', ', $values).")";
	}
	// Unshift the create statement for each table onto the beginning of our list of queries to run
	#foreach(array_keys($tables) as $tablename) array_unshift($queries, "create table if not exists `$tablename` (".implode(', ', $coldefs).")");
	array_unshift($queries, "create table if not exists `$tablename` (".implode(', ', $coldefs).")");

	// Run the queries
	foreach($queries as $query) mysql_query($query) or die(mysql_error());
}
#mysql_close($conn); //not really necessary according to: http://uk2.php.net/manual/en/function.mysql-close.php
?>
