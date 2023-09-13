#!/usr/bin/perl
#use warnings;
use strict;
use MBSEDialogsBackendLibs; 

my $block = "";
my $type = "";
my $targetLink = "";
my $rhpProject = "";

$block = $ARGV[0];
$type = $ARGV[1];
$targetLink = $ARGV[2];
$rhpProject = $ARGV[3];
#my $targetLink = "https://jazz.net/sandbox01-rm/resources/BI_H6ar9SnLEe2zB-tVgYH0_w";


#Linux
my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);

my $fullPath = $workspace  . "\/" .  $rhapsody_file_dir;
my $searchPath = $fullPath ;

if ($rhpProject eq "") {
	print "\n \nCommand executed with missing parameters\n"; 
	print "Usage: 2-linkToRequirement <Existing model_element> <type_of_the_model_element> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if (($block eq "") or ($type eq ""))  {
	print "Please provide the name of the model elemenet and its type to link with the given requirement... \n";
	print "Usage: 2-linkToRequirement <Existing model_element> <type_of_the_model_element> <Rhapsody Project Name>\n"; 
	exit -1; 
}


if (($projectArea eq "") or ($workspace eq "") or ($rhapsody_file_dir eq "")) {
	print "\n\nPlease check the name of the rhapsody project. No workspace or project area or rhapsody file location found for the provided project name\n"; 
	print "Usage: 2-linkToRequirement <Existing model_element> <type_of_the_model_element> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if ($projectArea eq "NULL") {$projectArea = "";}
else {$projectArea = "_" . $projectArea;}

my $origFileContents = "";


my $parentFolders = qx/find $fullPath \-type f \-exec grep \-H \'$block\' \{\} \\\;/;
my $fileName = findCorrectFileName($parentFolders, $block);

 if (($fileName eq "") or ($fileName eq "ERROR")) {
	
	print "ERROR: Parent Block could not be found. Please enter an existing Block as parent block\n\n\n";
	exit -1; 
 }


#file operations: Open the file which keeps the parent block. 

open (READ_PRT, '<', $fileName) or die "Cannot open file: $fileName";

while (<READ_PRT>){
	chomp($_);
	if ($origFileContents eq "") {
		$origFileContents = $_ . "\n";
	}
	else {
		$origFileContents = $origFileContents . $_ . "\n"; 
	}

}
close (READ_PRT);

# find the rmserverID of the Block to be linked 
my $rmServerID = findRmid($block, $origFileContents, "I" . $type);
# find the GUID of the block to be linked 
my $GUID = findGuid($block, $origFileContents, "I" . $type);

if ($rmServerID eq "ERROR") { 
	print "Model element or type not Found. Please make sure you entered right element and type:\n"; 
	print "please enter Class for Block\n"; 
	print "Subsystem for Package\n"; 
	print "Port for Proxy Ports\n"; 
	print "Part for Parts\n"; 
	print "etc...\n";
	exit -1; 
}

if ($GUID eq "ERROR") {
	print "Model element or type not Found. Please make sure you entered right element and type:\n"; 
	print "please enter Class for Block\n"; 
	print "Subsystem for Package\n"; 
	print "Port for Proxy Ports\n"; 
	print "Part for Parts\n"; 
	print "etc...\n";
	exit -1; 
}


my $oslcLink = "<IOslcLink type=\"e\">
				<_source type=\"a\">" . $rmServerID . "<\/_source>
				<_sourceGUID type=\"a\">" . $GUID . "<\/_sourceGUID>
				<_target type=\"a\">" . $targetLink . "<\/_target>
				<_type type=\"a\">http://jazz.net/ns/dm/linktypes#satisfy<\/_type>
				</IOslcLink>";
				
my $linkExists = findIfOSLCExists($origFileContents, $targetLink, $rmServerID);

if ($linkExists eq "false") {
	my $oslcInserted = insertOSLC($origFileContents, $oslcLink);
	$origFileContents = $oslcInserted;
}


#write to File... 
open (WR, '>', $fileName) or die "Cannot open file: $fileName";

my @contentArray = split(/\n/, $origFileContents);
foreach (@contentArray){
	chomp($_);
	print WR "$_\n"; 
}

close (WR);

fixRhapsodyIndicies($fileName);
print "Command completed successfully\n";


