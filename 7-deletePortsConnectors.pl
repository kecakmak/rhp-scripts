

#!/usr/bin/perl

use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;



# inputs
my $deletConnector = $ARGV[0];
my $rhpProject = $ARGV[1];


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

Contents: 
1. Find the Rhapsody file where the connector resides 
2. Find GUID of the connector in the Rhapsody file 
3. Find the connector tag of the connnector
4. Delete the connectory tag line by line
5. find the parent block of the connector 
6. find the rhapsody file where the parent block resides 
7. Delete the aggregates list entry in the parent block file 
8. find the RMM entry in the rhapsody file of the connector 
9. delete the RMM entry as well 
10. Update indicies 


