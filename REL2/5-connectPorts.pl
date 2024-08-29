

#!/usr/bin/perl

use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;



# inputs
my $fromPart = $ARGV[0];
my $fromPort = $ARGV[1];
my $toPart = $ARGV[2];
my $toPort = $ARGV[3]; 
my $rhpProject = $ARGV[4];


# Initialize the global variables. 
#Linux

my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);

my $fullPath = $workspace  . "\/" .  $rhapsody_file_dir;
my $searchPath = $fullPath ;


my $connectTemplate = "connection_template.xml";
my $connectIndexTemplate = "connection_index_template.xml";


if (($fromPart eq "") or ($fromPort eq "") or ($toPart eq "") or ($toPort eq ""))  {
	print "ERROR(102): Please provide the from and to part names to connect, and their relevant ports correctly... \n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1; 
}


if ($rhpProject eq "") {
	print "\nERROR(102): The Rhapsody Project Name is required. Please add Rhapsody Project Name\n"; 
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if (($projectArea eq "") or ($workspace eq "") or ($rhapsody_file_dir eq "")) {
	print "\nERROR(202): Please check the name of the rhapsody project. No workspace or project area or rhapsody file location found for the provided project name\n"; 
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if ($projectArea eq "NULL") {$projectArea = "";}
else {$projectArea = "_" . $projectArea;}


my $origFileContents = "";
my $fromPartFileContents = "";
my $toPartFileContents = ""; 
my $fromBlockFileContents = "";
my $toBlockFileContents = ""; 
my $parentGuid = "";
my $parentPackage = "";


# Other required information 
my $connName = ""; 
my $connGUID = ""; 
my $connRMID = ""; 
my $toPartName = $toPart;
my $fromPartName = $fromPart;
my $toBlockName = "";
my $fromBlockName = "";
my $parentFromBlock = ""; 
my $parentToBlock = "";
my $toPartGUID = "";
my $toPartRMID = "";
my $fromPartGUID = "";
my $fromPartRMID = ""; 
my $toPortGUID = "";
my $toPortRMID = ""; 
my $fromPortGUID = ""; 
my $fromPortRMID = ""; 

$connName = $toPartName . "_" . $fromPartName; 
my $connIds = getIds($searchPath);

if ($connIds eq "") {
	print "\nError: Check the IDs file\n\n\n";
	exit -1;
}

($connGUID, $connRMID) = split(/,/,$connIds); 
$connName = $fromPartName . "_" . $toPartName; 

my $toPartFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$toPartName\' \{\} \\\;/;
my $fromPartFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$fromPartName\' \{\} \\\;/;

my $toPartFileName = findCorrectFileName($toPartFileNames, $toPartName); 
my $fromPartFileName = findCorrectFileName($fromPartFileNames, $fromPartName);

if (($toPartFileName eq "ERROR") or ($fromPartFileName eq "ERROR")) {
	print "\nERROR(202): Cannot find provided parts... Check if the part names provided are true\n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1;
}


open (READ_PRT, '<', $fromPartFileName) or die "ERROR(402): Cannot open file: $fromPartFileName";

while (<READ_PRT>){
	chomp($_);
	if ($fromPartFileContents eq "") {
		$fromPartFileContents = $_ . "\n";
	}
	else {
		$fromPartFileContents = $fromPartFileContents . $_ . "\n"; 
	}

}
close (READ_PRT);

if ($toPartFileName eq $fromPartFileName) {$toPartFileContents = $fromPartFileContents;}

else { 
	open (READ_PRT, '<', $toPartFileName) or die "ERROR(402): Cannot Open File: $toPartFileName"; 

	while (<READ_PRT>){
		chomp($_);
		if ($toPartFileContents eq "") {
			$toPartFileContents = $_ . "\n";
		}
		else {
			$toPartFileContents = $toPartFileContents . $_ . "\n"; 
		}

	}
	close (READ_PRT);
}


#Find from and to Block Names... 
$fromPartGUID = findGuid($fromPartName, $fromPartFileContents, "IPart");
$fromPartRMID = findRmid($fromPartName, $fromPartFileContents, "IPart");

if (($fromPartGUID eq "ERROR") or ($fromPartRMID eq "ERROR")) {
	print "\nERROR(202): Cannot find provided part $fromPartName... Check if the part names provided are true1\n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing_to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1;
}

$fromBlockName = getBlockName($fromPartName, $fromPartFileContents, "IPart"); 

$parentFromBlock = findParentName($fromPartGUID, $fromPartFileContents, "IClass");

if ($parentFromBlock eq "ERROR") {
	print "\nERROR(202): Cannot find a parent Block for the provided part $fromPartName... Check if the part names provided are true2\n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1;
}



$toPartGUID = findGuid($toPartName, $toPartFileContents, "IPart");
$toPartRMID = findRmid($toPartName, $toPartFileContents, "IPart"); 

if (($toPartGUID eq "ERROR") or ($toPartRMID eq "ERROR")) {
	print "\nERROR(202): Cannot find provided part $toPartName... Check if the part names provided are true\n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1;
}

$toBlockName = getBlockName($toPartName, $toPartFileContents, "IPart");

$parentToBlock = findParentName ($toPartGUID, $toPartFileContents, "IClass");

if ($parentToBlock eq "ERROR") {
	print "\nERROR(202): Cannot find a parent Block for the provided part $toPartName... Check if the part names provided are true\n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1;
}

my $toBlockFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$toBlockName\' \{\} \\\;/;
my $fromBlockFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$fromBlockName\' \{\} \\\;/;

my $toBlockFileName = findCorrectFileName($toBlockFileNames, $toBlockName);
my $fromBlockFileName = findCorrectFileName($fromBlockFileNames, $fromBlockName);

if (($toBlockFileName eq "ERROR") or ($fromBlockFileName eq "ERROR")) {
	print "\nERROR(202): Cannot find main blocks for the provided ports ... Check if the port names provided are true\n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1;
}

my $parentFromBlockFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$parentFromBlock\' \{\} \\\;/;
my $parentFromBlockFileName = findCorrectFileName($parentFromBlockFileNames, $parentFromBlock);

my $parentToBlockFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$parentToBlock\' \{\} \\\;/;
my $parentToBlockFileName = findCorrectFileName($parentToBlockFileNames, $parentToBlock);

if (($parentFromBlockFileName eq "ERROR") or ($parentToBlockFileName eq "ERROR")) {
	print "\nERROR(202): Cannot find main blocks for the provided parts ... Check if the part names provided are true\n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1;
}

if ($fromBlockFileName eq $fromPartFileName) {$fromBlockFileContents = $fromPartFileContents;}

else { 
	open (READ_PRT, '<', $fromBlockFileName) or die "ERROR(402): Cannot open file: $fromBlockFileName";

	while (<READ_PRT>){
		chomp($_);
		if ($fromBlockFileContents eq "") {
			$fromBlockFileContents = $_ . "\n";
		}
		else {
			$fromBlockFileContents = $fromBlockFileContents . $_ . "\n"; 
		}

	}
	close (READ_PRT);
}
my $count = 0;
my $index = 0;
my $fromPortGUIDs = findGuid($fromPort, $fromBlockFileContents, "IPort");


if (index($fromPortGUIDs, ",")!=-1) {
	my @fromPortGUID_arr = split(/,/,$fromPortGUIDs);
	$count=$count+1;
	foreach (@fromPortGUID_arr) {
		chomp($_);
		my $fromParentCheck = findParentName($_, $fromBlockFileContents, "IClass");
		if ($fromParentCheck ne $fromBlockName) {next;}
		else {
			$fromPortGUID = $_;
			$index = $count;
		}
	}
}
else {$fromPortGUID = $fromPortGUIDs;}


my $fromPortRMIDs = findRmid($fromPort, $fromBlockFileContents, "IPort"); 

if (index($fromPortRMIDs, ",")!=-1) {
	my @fromPortRMID_arr = split(/,/,$fromPortRMIDs);
	$fromPortRMID = $fromPortRMID_arr[$index];
}
else {$fromPortRMID = $fromPortRMIDs;}

if (($fromPortGUID eq "ERROR") or ($fromPortRMID eq "ERROR")) {
	print "\nERROR(202): Cannot find provided port $fromPort... Check if the part names provided are true\n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1;
}

if ($toBlockFileName eq $fromPartFileName) {$toBlockFileContents = $fromPartFileContents;}

else { 
	open (READ_PRT, '<', $toBlockFileName) or die "ERROR(402): Cannot open file $toBlockFileName";

	while (<READ_PRT>){
		chomp($_);
		if ($toBlockFileContents eq "") {
			$toBlockFileContents = $_ . "\n";
		}
		else {
			$toBlockFileContents = $toBlockFileContents . $_ . "\n"; 
		}

	}
	close (READ_PRT);
}


#$toPortGUID = findGuid($toPort, $toBlockFileContents, "IPort");
#$toPortRMID = findRmid($toPort, $toBlockFileContents, "IPort"); 

$count = 0;
$index = 0;
my $toPortGUIDs = findGuid($toPort, $toBlockFileContents, "IPort");
if (index($toPortGUIDs, ",")!=-1) {
	my @toPortGUID_arr = split(/,/,$toPortGUIDs);
	$count=$count+1;
	foreach (@toPortGUID_arr) {
		chomp($_);
		my $toParentCheck = findParentName($_, $toBlockFileContents, "IClass");
		if ($toParentCheck ne $toBlockName) {next;}
		else {
			$toPortGUID = $_;
			$index = $count;
		}
	}
}
else {$toPortGUID = $toPortGUIDs;}


my $toPortRMIDs = findRmid($toPort, $toBlockFileContents, "IPort"); 

if (index($toPortRMIDs, ",")!=-1) {
	my @toPortRMID_arr = split(/,/,$toPortRMIDs);
	$toPortRMID = $toPortRMID_arr[$index];
}
else {$toPortRMID = $toPortRMIDs;}


if (($toPortGUID eq "ERROR") or ($toPortRMID eq "ERROR")) {
	print "\nERROR(202): Cannot find provided port $toPort... Check if the part names provided are true\n";
	print "Usage: 5-connectPorts.pl <Existing from_part_name> <Existing_port_of_the_from_part> <Existing to_part_name> <Existing_port_of_the_from_part> <Rhapsody Project Name>\n"; 
	exit -1;
}

my $fromPortIsCorrect = checkPartPort($fromBlockFileContents, $fromBlockName, $fromPortGUID);
my $toPortIsCorrect = checkPartPort($toBlockFileContents, $toBlockName, $toPortGUID);

if ($fromPortIsCorrect eq "false"){

	print "\nERROR(202): Wrong Port value entered for the part: $fromPart\nPlease check values and try again\n";
	exit -1;
}
if ($toPortIsCorrect eq "false"){

	print "\nERROR(202): Wrong Port value entered for the part: $toPart\nPlease check values and try again\n";
	exit -1;
}

open (CONN_R, '<', $connectTemplate) or die "ERROR(402): Cannot open file: $connectTemplate";  
my $templContents = "";
while(<CONN_R>) {
	chomp($_); 
	if ($templContents eq "") {$templContents = $_ . "\n";}
	else {$templContents = $templContents . $_ . "\n";} 
}
close(CONN_R);


open (CONNIN_R, '<', $connectIndexTemplate) or die "ERROR(402): Cannot open file: $connectIndexTemplate"; 
my $templIndexContents = "";
while(<CONNIN_R>) {
	chomp($_); 
	if ($templIndexContents eq "") {$templIndexContents = $_ . "\n";}
	else {$templIndexContents = $templIndexContents . $_ . "\n";} 
}
close(CONNIN_R);




my $mainFileName = $parentFromBlockFileName; 

# is From Part in the same file as the From Parent Block? 
if ($fromPartFileName eq $mainFileName) {
		$templContents =~s/<if_different_frompart><\/if_different_frompart>\n//ig;
}
else {
	my $fromPartDiff = "<_hfilename type=\"a\">$fromPartFileName<\/_hfilename>\n\t\t\t\t\t<_hsubsystem type=\"a\"><\/_hsubsystem>\n\t\t\t\t\t<_hclass type=\"a\">$parentFromBlock<\/_hclass>\n\t\t\t\t\t<_hname type=\"a\">$fromPart<\/_hname>";
	$templContents =~s/<if_different_frompart><\/if_different_frompart>/$fromPartDiff/ig;	
#	my $recursiveParents = getPath($fromPartGUID, $searchPath);
}

if ($toPartFileName eq $mainFileName) {
	$templContents =~s/<if_different_topart><\/if_different_topart>//ig;			
}
else {
	my $toPartDiff = "<_hfilename type=\"a\">$toPartFileName<\/_hfilename>\n\t\t\t\t\t<_hsubsystem type=\"a\"><\/_hsubsystem>\n\t\t\t\t\t<_hclass type=\"a\">$parentToBlock<\/_hclass>\n\t\t\t\t\t<_hname type=\"a\">$toPart<\/_hname>";
	$templContents =~s/<if_different_topart><\/if_different_topart>/$toPartDiff/ig;		
#	my $recursiveParents = getPath($toPartGUID, $searchPath);

}

if ($fromBlockFileName eq $mainFileName) {
	$templContents =~s/<if_different_fromport><\/if_different_fromport>//ig;
}
else {
		
	my $formPortDiff = "<_hfilename type=\"a\">$fromBlockFileName<\/_hfilename>\n\t\t\t\t\t<_hsubsystem type=\"a\"><\/_hsubsystem>\n\t\t\t\t\t<_hclass type=\"a\">$fromBlockName<\/_hclass>\n\t\t\t\t\t<_hname type=\"a\">$fromPort<\/_hname>";
	$templContents =~s/<if_different_fromport><\/if_different_fromport>/$formPortDiff/ig;
#	my $recursiveParents = getPath($fromBlockFileName, $parentFromBlock, $fromBlockName, $searchPath);
}


if ($toBlockFileName eq $mainFileName) {
	$templContents =~s/<if_different_toport><\/if_different_toport>//ig;	
}
else {
	my $toPortDiff = "<_hfilename type=\"a\">$toBlockFileName<\/_hfilename>\n\t\t\t\t\t<_hsubsystem type=\"a\"><\/_hsubsystem>\n\t\t\t\t\t<_hclass type=\"a\">$toBlockName<\/_hclass>\n\t\t\t\t\t<_hname type=\"a\">$toPort<\/_hname>";
	$templContents =~s/<if_different_toport><\/if_different_toport>/$toPortDiff/ig;
#	my $recursiveParents = getPath($toBlockFileName, $parentToBlock, $toBlockName, $searchPath);

}

my $date = getDate();
my $browserGUID="";
my $groupGUID=""; 
my $idGUID="";
	

	
	
	$templContents =~s/_PROJECTAREAID_HERE/$projectArea/ig;
	$templContents =~s/CURRENTDATE_HERE/$date/ig;
	$templContents =~s/TOPARTGUID_HERE/$toPartGUID/ig;
	$templContents =~s/TOPARTRMID_HERE/$toPartRMID/ig;
	$templContents =~s/FROMPARTGUID_HERE/$fromPartGUID/ig;
	$templContents =~s/FROMPARTRMID_HERE/$fromPartRMID/ig;
	$templContents =~s/TOPORTRMID_HERE/$toPortRMID/ig;
	$templContents =~s/TOPORTGUID_HERE/$toPortGUID/ig;
	$templContents =~s/FROMPORTGUID_HERE/$fromPortGUID/ig;	
	$templContents =~s/FROMPORTRMID_HERE/$fromPortRMID/ig;
	$templContents =~s/CONNNAME_HERE/$connName/ig;
	$templContents =~s/CONNGUID_HERE/$connGUID/ig;
	$templContents =~s/CONNRMID_HERE/$connRMID/ig;
	$templContents =~s/IDGUID_HERE/$idGUID/ig;


	$templIndexContents =~s/_PROJECTAREAID_HERE/$projectArea/ig;
	$templIndexContents =~s/CURRENTDATE_HERE/$date/ig;
	$templIndexContents =~s/TOPARTGUID_HERE/$toPartGUID/ig;
	$templIndexContents =~s/TOPARTRMID_HERE/$toPartRMID/ig;
	$templIndexContents =~s/FROMPARTGUID_HERE/$fromPartGUID/ig;
	$templIndexContents =~s/FROMPARTRMID_HERE/$fromPartRMID/ig;
	$templIndexContents =~s/TOPORTRMID_HERE/$toPortRMID/ig;
	$templIndexContents =~s/TOPORTGUID_HERE/$toPortGUID/ig;
	$templIndexContents =~s/FROMPORTGUID_HERE/$fromPortGUID/ig;	
	$templIndexContents =~s/FROMPORTRMID_HERE/$fromPortRMID/ig;
	$templIndexContents =~s/CONNNAME_HERE/$connName/ig;
	$templIndexContents =~s/CONNGUID_HERE/$connGUID/ig;
	$templIndexContents =~s/CONNRMID_HERE/$connRMID/ig;
	$templIndexContents =~s/BROWSERGUID_HERE/$browserGUID/ig;
	$templIndexContents =~s/GROUPGUID_HERE/$groupGUID/ig;
	

	
	
open (READ_PRT, '<', $mainFileName) or die "ERROR(402): Cannot open file: $mainFileName";

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

my $fileContentsWithDCBlockAgg =  aggregateBlock($parentFromBlock, $connGUID, $origFileContents, "IClass");
$origFileContents = $fileContentsWithDCBlockAgg;

my $fileContentsWithConn = insertChild($origFileContents, $templContents, $parentFromBlock, "IClass");
$origFileContents = $fileContentsWithConn;

my $newConnIndexAddedFileContents = insertNewIndex($origFileContents, $templIndexContents, $parentFromBlock);
$origFileContents = $newConnIndexAddedFileContents;



my $trimmedFileContents = trimFileContents($origFileContents); 
$origFileContents = $trimmedFileContents;

#write to File... 
open (WR, '>', $mainFileName) or die "ERROR (402): Cannot open file: $mainFileName";
# binmode WR;

my @contentArray = split(/\n/, $origFileContents);
foreach (@contentArray){
	chomp($_);
	print WR "$_\n"; 
}

close (WR);

fixRhapsodyIndicies($mainFileName);

print "Command completed successfully\n";




