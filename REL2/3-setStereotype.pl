#!/usr/bin/perl

#use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;

# inputs
my $blockName = $ARGV[0];
my $rhpProject = $ARGV[1];
my $third = "";
$third = $ARGV[2]; 
my $stCode = "";

if ($third ne "") {
	$stCode = $rhpProject;
	$rhpProject = $third;
}


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
	print "Usage: 3-setStereotype <Existing block_name> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if ($blockName eq "")  {
	print "ERROR(202): Please provide the name of the block... \n";
	print "Usage: 3-setStereotype <Existing block_name> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if (($projectArea eq "") or ($workspace eq "") or ($rhapsody_file_dir eq "")) {
	print "\nERROR(202): Please check the name of the rhapsody project. No workspace or project area or rhapsody file location found for the provided project name\n"; 
	print "Usage: 3-setStereotype <Existing block_name> <Rhapsody Project Name>\n"; 
	exit -1; 
}

if ($projectArea eq "NULL") {$projectArea = "";}
else {$projectArea = "_" . $projectArea;}


my $origFileContents = ""; 
my $profileContents = ""; 
my $stName = ""; 

my $parentFolders = qx/find $searchPath \-type f \-exec grep \-H \'$blockName\' \{\} \\\;/;
my $parentFolder = findCorrectFileName_withType($parentFolders, $blockName, "Class");
my $fileName = $parentFolder; 

 if (($parentFolder eq "") or ($parentFolder eq "ERROR")) {
	
	print "ERROR(202): The Block $blockName could not be found. Please enter an existing Block to set the stereotype\n\n\n";
	exit -1; 
 }


#file operations: Open the file which keeps the parent block. 

open (READ_PRT, '<', $fileName)  or die "ERROR(402): File $fileName Not Found!!";

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


my $blockGuid = findGuid($blockName, $origFileContents, "IClass"); 


# To find Stereotype first read the file 
my $projectFilePath = $workspace  . "\/" . $rhpProjectFile;

my $profileFile = "";
my $relProfileFile = "";
my $profilePath = findNVLProfilePath($projectFilePath); 

if ($profilePath eq "ERROR"){
	print "ERROR(402): Stereotype profile File not found!! Exiting.... ";
	exit -1;
}

elsif ($profilePath eq "workspace") {
	$profilePath = $fullPath;
	 $relProfileFile = ".\\MBGrV.sbsx";
}

else{
	$relProfileFile = $profilePath . "\\" . "MBGrV.sbsx";
	$profilePath = $wsPath . "\/" . $profilePath . "\/";	
}

$profileFile = $profilePath . "MBGrV.sbsx"; 



$profileFile =~s/\\/\//ig;
$profileFile =~s/\/..\/..\//\//ig;


open (READ_PROF, '<', $profileFile) or die "ERROR(402): Profile File $profileFile Not Found!!"; 

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



# 1. Get the Block number from Block name 
my ($bl,$level,$bId) = split(/_/,$blockName);

# 2. Identify the system level from the block name 
if ($level eq "HBA") {$level = 1;} 
elsif ($level eq "BA") {$level = 2;} 
elsif ($level eq "HBGR") {$level = 3;}
elsif ($level eq "BGR") {$level = 4;} 
else {$level = "NA";} 

# 3. Match the block id with stereotype name 
my @contentArr=split(/\n/, $profileContents); 

if ($stCode ne "") {$bId = $stCode;}
	
foreach(@contentArr) {
	chomp($_); 
	my $line = $_; 
	if (index($line, "=\"a\">" . $bId . "_") !=-1){
		$line =~s/<_name type=\"a\">//ig;
		$line =~s/<\/_name>//ig;
		$line =~s/\t//ig;
		$line =~s/\n//ig;
		$stName = $line; 

	}
}

	$stName=~s/\\par//ig;
	$stName=~s/\\'e4/ä/ig;
	$stName=~s/\\'fc/ü/ig;
	$stName=~s/\\'dc/Ü/ig;
	$stName=~s/\\'f6/ö/ig;
	$stName=~s/\\'df/ß/ig;
	$stName=~s/\\/Ö/ig;
	$stName=~s/\\'c4/Ä/ig;

	
	$profileContents =~s/\%E4/ä/ig;
	$profileContents =~s/\%FC/ü/ig;
	$profileContents =~s/\%DC/Ü/ig;
	$profileContents =~s/\%F6/ö/ig;
	$profileContents =~s/\%DF/ß/ig;
	$profileContents =~s/\%/Ö/ig;
	$profileContents =~s/\%C4/Ä/ig;

my $stGuid = findGuid($stName, $profileContents, "IStereotype"); 

if ($stGuid eq "ERROR") {
	print "ERROR(202): No matching stereotype found. Please set the stereotype manually, for the block: $blockName";
	exit (-1);
}

my @parentName = ""; 
my @parentGuid = ""; 
my $recursiveParents = ""; 

if ($level ne "NA") {
	my $inGuid = $stGuid;
	for (my $i = 0; $i < $level ; $i++) {
		$parentName[$i] = findParentName($inGuid, $profileContents, "ISubsystem");
		$parentGuid[$i] = findGuid($parentName[$i], $profileContents, "ISubsystem");
		$inGuid = $parentGuid[$i];
		if ($recursiveParents eq "") {$recursiveParents = $parentName[$i];}
		else {$recursiveParents = $parentName[$i] . "::" . $recursiveParents;} 	
		}	
}

else {
	print "ERROR(202): No matching stereotype found. Please set the stereotype manually, for the block: $blockName";
	exit (-1);
}

$recursiveParents = "NVL_Profile::Blocks::" . $recursiveParents; 

my $stereotypeAdd = createNewStereotype($recursiveParents, $stName, $stGuid, $relProfileFile);  


my $stAddedFileContents = insertStereotype($origFileContents, $blockName, $stereotypeAdd, $stGuid, "IClass"); 
$origFileContents = $stAddedFileContents; 


my $appendedStToBlockIndex = appendStToBlockIndex($origFileContents, $blockName, $stName);
$origFileContents = $appendedStToBlockIndex; 



my $trimmedFileContents = trimFileContents($origFileContents); 
$origFileContents = $trimmedFileContents;


#write to File... 
open (WR, '>', $fileName) or die "ERROR(402): File $fileName Not Found!!";
# binmode WR;

my @contentArray = split(/\n/, $origFileContents);
foreach (@contentArray){
	chomp($_);
	print WR "$_\n"; 
}

close (WR);

fixRhapsodyIndicies($fileName);
my $homeDir = $ENV{HOME};
my $dir = $homeDir . "/" . $rhpProject;
my $file = $homeDir . "/" . $rhpProject . "/blockList.json";
my $logFile = $homeDir . "/" . $rhpProject . "/logFile.txt";

my $dirExists = `ls $ dir 2>&1`; 

if (index($dirExists, "No such file")!=-1) {`mkdir $dir 2>&1`; }


my $command = "perl 0-listBlocksBackgrd.pl " . $rhpProject; 

my $output = system($command . " > $logFile &");

print "Command completed successfully\n";



