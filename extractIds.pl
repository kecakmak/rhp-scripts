

#!/usr/bin/perl

use warnings;
use strict;

my $workspace = "C:\\Users\\kerimcakmak\\workspace2\\NVL\\SETitanic\\";

my $rhapsody_file_dir = "ACC_rpy\\";
my $importFile = "import.sbsx"; 

my $idFile = "IDs.txt";

my $fileName = $workspace . $rhapsody_file_dir . $importFile; 
my $idFileName = $workspace . $rhapsody_file_dir . $idFile;

open (FIRST, '>' , $idFileName);
close(FIRST);
open (OUT, '>', $idFileName);
open(IN, '<', $fileName) or die; 


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

#}
