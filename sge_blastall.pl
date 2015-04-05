#! /usr/bin/perl
use warnings;
use strict;
use Schedule::DRMAAc qw/ :all /;

## Program Info:
#
# Name: <enter name here>
#
# Function: <description of what this does>
#
# Author: Andre Villegas
#
# Copyright (c) Public Health Agency of Canada, 20XX-20XX
# All Rights Reserved.
#
# Licence: This script may be used freely as long as no fee is charged
#    for use, and as long as the author/copyright attributions
#    are not removed. It remains the property of the copyright holder.
#
# History:
#
# Usage:

my $args = \@ARGV;
my $error;
my $diagnosis;
my $jt;
my $jobid;
my $drmerr;
my $drmdiag;

$ENV{'SGE_ROOT'} = '/opt/gridengine';
$ENV{'SGE_QMASTER_PORT'} = '6444';
$ENV{'SGE_EXECD_PORT'} = '6445';

( $error, $diagnosis ) = drmaa_init( undef );
die drmaa_strerror( $error ) . "\n" . $diagnosis if $error;

( $error, $jt, $diagnosis ) = drmaa_allocate_job_template();
die drmaa_strerror( $error ) . "\n" . $diagnosis if $error;

( $error, $diagnosis ) = drmaa_set_attribute( $jt, $DRMAA_REMOTE_COMMAND, '/usr/molbin/blast/bin/blastall' );
die drmaa_strerror( $error ) . "\n" . $diagnosis if $error;

($drmerr,$drmdiag) = drmaa_set_attribute($jt,$DRMAA_OUTPUT_PATH,":/tmp/"); #sets the output directory for stdout
die drmaa_strerror($drmerr)."\n".$drmdiag if $drmerr;

($drmerr,$drmdiag) = drmaa_set_attribute($jt,$DRMAA_ERROR_PATH,":/tmp/"); #sets the output directory for stderr
die drmaa_strerror($drmerr)."\n".$drmdiag if $drmerr;

( $error, $diagnosis ) = drmaa_set_vector_attribute( $jt, $DRMAA_V_ARGV, $args );
die drmaa_strerror( $error ) . "\n" . $diagnosis if $error;

( $error, $jobid, $diagnosis ) = drmaa_run_job( $jt );
die drmaa_strerror( $error ) . "\n" . $diagnosis if $error;

my @job_constant = ( $DRMAA_JOB_IDS_SESSION_ALL );
( $error, $diagnosis ) = drmaa_synchronize( \@job_constant , $DRMAA_TIMEOUT_WAIT_FOREVER, 0 );
die drmaa_strerror( $error ) . "\n" . $diagnosis if $error;

( $error, $diagnosis ) = drmaa_delete_job_template( $jt );
die drmaa_strerror( $error ) . "\n" . $diagnosis if $error;
