#!/usr/bin/perl

## Program Info:
#
# Name: println.pl
#
# Function: Helper function to be included in other scripts so one could do a
#	    println command and not have to use \n everwhere 
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 2009-2010
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# History:
# v0.0	Dec 2 2009	- created file
#
# Usage: include "~/bin/println.pl";  then println "blah";

sub println {
    local $\ = "\n";
    print @_;
}
1;
