
#!/usr/bin/perl

#use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;


# inputs
my $portPart = $ARGV[0];
my $existingPortName = $ARGV[1];
my $newPortName = $ARGV[2];
my $rhpProject = $ARGV[3];

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
	exit -1; 
}

if (($portPart eq "") or ($newPortName eq "") or ($existingPortName eq ""))  {
	print "ERROR(102): Please provide the name of the existing block, the name for the existing port and a new name for the existing port... \n";
	exit -1; 
}


if (($projectArea eq "") or ($workspace eq "") or ($rhapsody_file_dir eq "")) {
	print "\nERROR(202): Please check the name of the rhapsody project. No workspace or project area or rhapsody file location found for the provided project name\n"; 
	exit -1; 
}

if ($projectArea eq "NULL") {$projectArea = "";}
else {$projectArea = "_" . $projectArea;}



my $portsAll = justListPortsCommon($portPart,$searchPath);

	my ($parentFromBlockandPart, $fromPorts) = split(/==/,$portsAll);
	my ($parentFromBlockPart_all,$parentFromBlock) = split("-OFPART-",$parentFromBlockandPart);
	my ($parentFromBlockID, $parentFromBlockPart) = split("PARTBLOCK_SEPERATOR", $parentFromBlockPart_all);
		
	my @ports_arr = split("::",$fromPorts); 
	my $portNameToChange = ""; 
	my $portGUIDToChange = "";
	
	foreach(@ports_arr){ 
		chomp($_);
		my($rhpPortInfo, $rmPortInfo) = split("RM_SEPERATOR", $_); 
		my ($portName, $portGUID) = split(/\|\|/,$rhpPortInfo); 
		if ($portName eq $existingPortName){ 
			$portNameToChange = $portName; 
			$portGUIDToChange = $portGUID;
		}
	}
	if ($portNameToChange eq "") {
		print "ERROR(202): Port $existingPortName cannot be found under the part name: $portPart.\nPlease check the part name and the port name\n";
		exit -1;
	}

my $portFileNames = qx/find $searchPath \-type f \-exec grep \-H \'<_name type=\"a\">$portNameToChange\' \{\} \\\;/;
my $portFileName = findCorrectFileName_withType($portFileNames, $portNameToChange, "Port"); 


my $portFileContents = getFileContents($portFileName);
my $contentsWithChangedPortName = renameElement($portFileContents,$portNameToChange,$portGUIDToChange,$newPortName,"IPort");


#write to File... 
open (WR, '>', $portFileName) or die "ERROR(402): Cannot open file: $portFileName";

my @contentArray = split(/\n/, $contentsWithChangedPortName);
foreach (@contentArray){
	chomp($_);
	print WR "$_\n"; 
}

close (WR);

fixRhapsodyIndicies($portFileName);

print "Command completed successfully\n";



