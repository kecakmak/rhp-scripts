#!/usr/bin/perl

use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;

my $rhpProject = $ARGV[0];

my $homeDir = $ENV{HOME};
my $dir = $homeDir . "/" . $rhpProject;
my $file = $homeDir . "/" . $rhpProject . "/blockList.json";
my $logFile = $homeDir . "/" . $rhpProject . "/logFile.txt";

my $dirExists = `ls $ dir 2>&1`; 

if (index($dirExists, "No such file")!=-1) {`mkdir $dir 2>&1`; }

my $jsonExists = `ls $file 2>&1`; 

if (index($jsonExists, "No such file")!=-1) {

	my $command = "perl 0-listBlocksBackgrd.pl " . $rhpProject; 

	my $output = system($command . " > $logFile");

}


	open (READ_PRT, '<', "$file") or die "Cannot open file $file" ; 

	while (<READ_PRT>){
		chomp($_);
		print "$_\n";
	}
	close (READ_PRT);

	exit 0;




