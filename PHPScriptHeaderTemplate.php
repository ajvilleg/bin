<?php
/* Program Info:

   Name: <Name of Program>.php

   Function: 

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
$input;

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

/* THIS SECTION DOESN'T WORK FIX IT!
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

// THE REST OF YOUR CODE
*/
?>
