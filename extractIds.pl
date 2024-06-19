

#!/usr/bin/perl

use warnings;
use strict;

print "Please enter the Rhapsody project directory in your workspace:\nEg: C:\\..\\NEW-NVL-Windows\\NVL Sample\\Project\\SETitanic\\Projekt_SETitanic_rpy\n\n";
print "For help, please enter help\n"; 
my $string = <STDIN>;
chomp ($string);

if ($string eq "help") {
	
	print "This script can only be used in Windows. \nThe import.sbsx file should be checked in from Rhapsody in order to extract the ids. \nSince this change is not yet delivered, the imports.sbsx file can only be accessed on the client which has access to the checked in import.sbsx file.\n";
	exit (0);
}

my $workspace = $string;


my $importFile = "\\import.sbsx"; 

my $idFile = "\\IDs.txt";

my $fileName = $workspace  . $importFile; 
my $idFileName = $workspace . $idFile;

open (OUT, '>', $idFileName) or die "\nPlease check the file name to be true: $idFileName\nFor help, please enter -help\n\n";

open(IN, '<', $fileName) or die "\nPlease check the file name to be true: $fileName\nFor help, please enter -help\n\n"; 


#while(OUT){

	while(<IN>){
		my $guid = "";
		my $rmid = "";
		chomp($_); 
		my $line = $_; 
		
		if (index($line, "<_id type")!=-1) {
			$line=~s/<_id type=\"a\">//ig;
			$line=~s/<\/_id>//ig;
			$line=~s/\t//ig;
			$guid = $line;
			print OUT $guid . ",";
		}
		if (index($line, "<_rmmServerID type")!=-1) {
			$line=~s/<_rmmServerID type=\"a\">//ig;
			$line=~s/<\/_rmmServerID>//ig;
			$line=~s/\t//ig;
			my ($onlyID, $project) = split(/_/,$line);
			$rmid = $onlyID;
			print OUT $rmid . "\n";
		}
	
	}
close (IN);
close (OUT);

print "\n\nSUCCESS: Id file created. Please check it at the location:\n $idFileName. \nIf everything is ok, please don't forget to checkin and deliver the file.";

#}