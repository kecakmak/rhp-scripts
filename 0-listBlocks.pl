#!/usr/bin/perl

use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;



open (READ_PRT, '<', "blockList.json") or die "Cannot open file"; 

while (<READ_PRT>){
	chomp($_);
	print "$_\n";
}
close (READ_PRT);

exit -1;

