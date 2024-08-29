

#!/usr/bin/perl

#use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;


# inputs
my $portBlock = $ARGV[0];
my $newPort = $ARGV[1];
my $newPortLabel = $ARGV[4];
my $portSt = $ARGV[2];
my $rhpProject = $ARGV[3];

if ($newPortLabel eq "") {$newPortLabel = $newPort;}


my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 
my $rhpProjectFileName = "RHAPSODY_FILE_NAME_" . $rhpProject; 

my $wsPath = getEnvironments("WORKSPACE");

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);
my $rhpProjectFile = getEnvironments($rhpProjectFileName);

my $fullPath = $workspace  . "\/" .  $rhapsody_file_dir;
my $searchPath = $fullPath ;

if ($rhpProject eq "") {
	print "\nERROR(102): Command executed with missing parameters\n";
	print "Usage: 4-createPorts.pl <Existing block_name> <name_for_the_new_port> <stereotype_name_for_the_new_port> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if (($portBlock eq "") or ($newPort eq "") or ($portSt eq ""))  {
	print "ERROR(102): Please provide the name of the existing block, a name for the port to be created and a stereotype value for the new port... \n";
	print "Usage: 4-createPorts.pl <Existing block_name> <name_for_the_new_port> <stereotype_name_for_the_new_port> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if (($portSt ne "IF_Mechanik") and ($portSt ne "IF_Software") and ($portSt ne "IF_Hardware") and ($portSt ne "IF_Weitere") and ($portSt ne "IF_Daten") and ($portSt ne "IF_Fluid")) {
	print "ERROR(102): Only allowed values for Port Stereotype is: \nIF_Mechanik\nIF_Software\nIF_Hardware\nIF_Weitere\nIF_Daten\nIF_Fluid\nPlease select one of those and try again\n"; 
	print "Usage: 4-createPorts.pl <Existing block_name> <name_for_the_new_port> <stereotype_name_for_the_new_port> <Rhapsody Project Name>\n"; 
	exit -1; 
}


if (($projectArea eq "") or ($workspace eq "") or ($rhapsody_file_dir eq "")) {
	print "\nERROR(202): Please check the name of the rhapsody project. No workspace or project area or rhapsody file location found for the provided project name\n"; 
	print "Usage: 4-createPorts.pl <Existing block_name> <name_for_the_new_port> <stereotype_name_for_the_new_port> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if ($projectArea eq "NULL") {$projectArea = "";}
else {$projectArea = "_" . $projectArea;}


my $origFileContents = ""; 
my $parentGuid = "";
my $parentPackage = ""; 
my $blockPackageExists = "false";
my $isSeperateFile = "false";
my $newPortIds = getIds($searchPath);
my $newPackageIds = getIds($searchPath);
my $newCompositeIds = getIds($searchPath);

my ($newPortGuid, $newPortRMId) = split(/,/,$newPortIds);


# Search the port name within the workspace

#use for Linux 
my $parentFolders = qx/find $searchPath \-type f \-exec grep \-H \'$portBlock\' \{\} \\\;/;
my $parentFolder = findCorrectFileName($parentFolders, $portBlock);

if ($parentFolder eq "ERROR") {
	print "\nERROR(202): Cannot find the block $portBlock to create the proxy port ... Check if the block exists\n";
	print "Usage: 4-createPorts.pl <Existing block_name> <name_for_the_new_port> <stereotype_name_for_the_new_port> <Rhapsody Project Name>\n"; 
	exit -1; 
}

my $fileName = $parentFolder; 


 if ($parentFolder eq "") {
	
	print "ERROR(202): The Block $portBlock could not be found. Please enter an existing Block to create the port\n\n\n";
	exit -1; 
 }

#file operations: Open the file which keeps the parent block. 

open (READ_PRT, '<', $fileName) or die "ERROR(402): Cannot open file: $fileName";

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

#check if Port Exists 
#if (index($origFileContents, $newPort)!=-1) {
#print "Port Exists!!!\n\n\n";
#exit -1;
#}

my $portExists = checkPortExists($origFileContents, $portBlock, $newPort);
if ($portExists eq "true"){
	print "ERROR(302): The port, $portBlock exists for Block: $portBlock!!!\n\n\n";
	exit -1;
}


# Find the GUID of the Parent Block 
my $blockGuid = findGuid($portBlock, $origFileContents, "IClass"); 


if ($blockGuid eq "ERROR") {
	print "ERROR(202): Parent Block $portBlock Cannot be found. Exiting..."; 
	exit -1;
	}
	
	
# We'll create the port from the port template now: 
my $newPortCreated = createNewPort($origFileContents, $newPortGuid, $newPortRMId, $newPort, $newPortLabel, $projectArea, $portSt, $fullPath, $rhpProject);


#Now insert the template into the correct file 
my $fileContentsWithPort = insertChild($origFileContents, $newPortCreated, $portBlock, "IClass");
$origFileContents = $fileContentsWithPort;



my $fileContentsWithDCBlockAgg =  aggregateBlock($portBlock, $newPortGuid, $origFileContents, "IClass");
$origFileContents = $fileContentsWithDCBlockAgg;

my $createPortIndex = createNewPortIndex($newPortRMId, $newPortGuid, $projectArea, $newPort, $newPortLabel, $rhpProject);



my $newPortIndexAddedFileContents = insertNewIndex($origFileContents, $createPortIndex, $portBlock);
$origFileContents = $newPortIndexAddedFileContents;



my $newPortIndexAlsoAppendedToParentBlock = appendNewBlockToPackageIndex($portBlock, $newPortRMId, $projectArea, $origFileContents);
$origFileContents = $newPortIndexAlsoAppendedToParentBlock;


#set the stereotypes 

# To find Stereotype first read the file 

my $projectFilePath = $workspace  . "\/" . $rhpProjectFile;
my $profileFile = "";
my $relProfileFile = "";
my $profilePath = findNVLProfilePath($projectFilePath);


if ($profilePath eq "ERROR"){
	print "ERROR(202): Stereotype profile File not found!! Exiting.... ";
	exit -1;
}

elsif ($profilePath eq "workspace") {
	$profilePath = $fullPath;
	 $relProfileFile = ".\\Ports.sbsx";
}

else{
	$relProfileFile = $profilePath . "\\" . "Ports.sbsx";
	$profilePath = $wsPath . "\/" . $profilePath . "\/";	
}

$profileFile = $profilePath . "Ports.sbsx"; 



$profileFile =~s/\\/\//ig;
$profileFile =~s/\/..\/..\//\//ig;


#my $profileFile = $profilePath ."\/" . "Ports.sbsx"; 
#my $relProfileFile = $profilePath . "\\" . "Ports.sbsx";

#$profileFile = $wsPath . "\/" . $profileFile;
#$profileFile =~s/\\/\//ig;
#$profileFile =~s/\/..\/..\//\//ig;

my $profileContents = ""; 

open (READ_PROF, '<', $profileFile) or die "ERROR(402): Cannot open file: $profileFile"; 

while (<READ_PROF>){
	chomp($_);
	if ($profileContents eq "") {
		$profileContents = $_ . "\n";
	}
	else {
		$profileContents = $profileContents . $_ . "\n"; 
	}

}
close (READ_PROF);

my $stName = $portSt; 


my $appendedStToBlockIndex = appendStToBlockIndex($origFileContents, $newPort, $stName);
$origFileContents = $appendedStToBlockIndex; 


my $trimmedFileContents = trimFileContents($origFileContents); 
$origFileContents = $trimmedFileContents;

#write to File... 
open (WR, '>', $fileName) or die "ERROR(402): Cannot open file: $fileName";

my @contentArray = split(/\n/, $origFileContents);
foreach (@contentArray){
	chomp($_);
	print WR "$_\n"; 
}

close (WR);

fixRhapsodyIndicies($fileName);

print "Command completed successfully\n";



