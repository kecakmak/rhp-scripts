

#!/usr/bin/perl

#use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;

# Initialize the global variables. 
# inputs
my $blockToCreate = "";
my $parentBlock = "";
my $rhpProject = "";
$parentBlock = $ARGV[0];
$rhpProject = $ARGV[2];
$blockToCreate = $ARGV[1];

if ($rhpProject eq "") {
	print "\n \nCommand executed with missing parameters\n"; 
	print "Usage: 1-createChildBlock <Existing parent block> <Name of the new block> <Rhapsody Project Name>\n\n"; 
	exit -1; 
}


#Linux
my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);

my $fullPath = $workspace  . "\/" .  $rhapsody_file_dir;
my $searchPath = $fullPath ;

if ($projectArea eq "NULL") {$projectArea = "";}
else {$projectArea = "_" . $projectArea;}

my $origFileContents = ""; 
my $parentGuid = "";
my $parentPackage = ""; 
my $blockPackageExists = "false";
my $isSeperateFile = "false";
my $newBlockIds = getIds($searchPath);
my $newPackageIds = getIds($searchPath);
my $newCompositeIds = getIds($searchPath);

my ($newBlockGuid, $newBlockRMId) = split(/,/,$newBlockIds);
my ($newPackageGuid, $newPackageRMId)  = split(/,/,$newPackageIds);
my ($newCompositeGuid, $newCompositeRMId) = split(/,/,$newCompositeIds);


my $blockPackage = (split "_", $blockToCreate) [-1];
$blockPackage = "ST_" . $blockPackage;

# Search the parent block in the files within the workspace

#use for Linux 
my $parentFolders = qx/find $fullPath \-type f \-exec grep \-H \'$parentBlock\' \{\} \\\;/;
my $parentFolder = findCorrectFileName($parentFolders, $parentBlock);
my $fileName = $parentFolder; 

 if (($parentFolder eq "") or ($parentFolder eq "ERROR")) {
	print "ERROR(202): Parent Block: $parentBlock could not be found. Please enter an existing Block as parent block\n\n\n";
	exit (-1); 
 }


#file operations: Open the file which keeps the parent block. 

open (READ_PRT, '<', $fileName) or die "ERROR(402): Cannot open file $fileName";

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


#print "$origFileContents\n";

#check if Block Exists 
my $isBlockNotNew = checkBlockExists($origFileContents, $blockToCreate); 

if ($isBlockNotNew eq "true") {
print "ERROR(302): Child Block: $blockToCreate already exists! Please try with a different name\n\n\n";
exit (-1);
}

# Find the GUID of the Parent Block 
$parentGuid = findGuid($parentBlock, $origFileContents, "IClass"); 

if ($parentGuid eq "ERROR") {
	print "ERROR(202): Parent Block, $parentBlock cannot be found. Exiting...\n\n"; 
	exit (-1);
	}
	
# Identify the parent Package where the parent Block resides. 
# Then we have to create a sub package under this parent package 
# Then we have to create a sub block under the sub package 

$parentPackage = findParentName($parentGuid, $origFileContents, "ISubsystem"); 

# Now we have to create a sub package under this parent package 
# Then we have to create a sub block under the sub package 
# But before these actions, first lets check if there is a sub-package defined already for the new block

$blockPackageExists = checkBlockPackage($blockPackage, $origFileContents); 

#if there is already a package for the new child block
if ($blockPackageExists eq "true") {
	$isSeperateFile = isFile($blockPackage, $origFileContents); 
#if there is already a package for the new child block and it is also a seperate file. 
	if ($isSeperateFile eq "true"){
		my $relativeFile = (split /\\/, $fileName)[-1];
		my $newRelativeFile = $blockPackage . ".sbsx";
		$fileName =~s/$relativeFile/$newRelativeFile/ig;
# now the filename that we need to update has changed.  
	}
}	
	
# Now we have to create a sub package under this parent package 
# Then we have to create a sub block under the sub package 

# lets get the Rhapsody file contents again. In case the file to update is different from the beginning.. 
$origFileContents = "";
open (READ_PRT, '<', $fileName) or die "ERROR(302): Cannot open file: $fileName";

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



##From now on we create the Block and its package 
if ($blockPackageExists eq "false") {
#block Package doesn't exist. Create the packge first 
	my $newPackageCreated = createBlockPackage($blockPackage, $newPackageGuid, $newBlockGuid, $projectArea, $newPackageRMId, $newCompositeRMId, $newCompositeGuid);
#then insert th's block to the main file 
	my $fileContentsWithPackage = insertChild($origFileContents, $newPackageCreated, $parentPackage, "ISubsystem");  
	$origFileContents = $fileContentsWithPackage;
#add the new block to the aggreate list of the parent block  
	my $fileContentsWithPackageAgg = aggregateBlock($parentPackage, $newPackageGuid, $origFileContents, "ISubsystem");
	$origFileContents = $fileContentsWithPackageAgg;

}
# Now, the package exists, just add the block guid under the Block Package that exists
	my $fileContentsWithBlockAgg = aggregateBlock($blockPackage, $newBlockGuid, $origFileContents, "ISubsystem");
	$origFileContents = $fileContentsWithBlockAgg;

#now create the block 
# but first update the template
my $newBlockCreated = createNewBlock($origFileContents, $newBlockGuid, $newBlockRMId, $blockToCreate, $projectArea, $rhpProject);


#Now insert the template into the correct file 
my $fileContentsWithBlock = insertChild($origFileContents, $newBlockCreated, $blockPackage, "ISubsystem");
$origFileContents = $fileContentsWithBlock;

#new Block is created and recorded in the origFileContents variable. We need to update the Rhapsody indicies now 



# check if there is already and index entry for the new package 
if (index($origFileContents, "<NAME>" . $blockPackage . "<\/NAME>")!=-1) {
#no need to create index for package. This index exists. So just, append the rm id of the new block 
	my $newBlockAppendedtoPackageIndex = appendNewBlockToPackageIndex($blockPackage, $newBlockRMId, $projectArea, $origFileContents);
	$origFileContents = $newBlockAppendedtoPackageIndex;
}

else {
 # Index doesn't exist for the package. First create the index for the package 
# then insert it to file Contents 
# finally, append the package to the parent package index. New Block will automatically been added to the block package index. No need to run the appendNewBlockToPackageIndex method for the block. 
	my $createPackageIndex = createNewPackageIndex($newPackageRMId, $newPackageGuid, $projectArea, $blockPackage, $newBlockRMId);
	my $newPackageIndexAddedFileContents = insertNewIndex($origFileContents, $createPackageIndex, $parentPackage);
	$origFileContents = $newPackageIndexAddedFileContents; 
	my $newPackageIndexAlsoAppendedToParent = appendNewBlockToPackageIndex($parentPackage, $newPackageRMId, $projectArea, $origFileContents);
	$origFileContents = $newPackageIndexAlsoAppendedToParent;
}

#now create the Block index the block is already appended to the package index 

my $createBlockIndex = createNewBlockIndex($newBlockRMId, $newBlockGuid, $projectArea, $blockToCreate, $rhpProject);

my $newBlockIndexAddedFileContents = insertNewIndex($origFileContents, $createBlockIndex, $blockPackage);
 $origFileContents = $newBlockIndexAddedFileContents;
 
#Directed Composition Functions 
	# 1. Create a Directed Composition between child and parent.  
my $dcIds = getIds($searchPath);
my($dcGuid, $dcRmid) = split(/,/,$dcIds); 

	# 2. Create DC and DC index from template 
my $dcEntry = createNewDC($dcGuid, $dcRmid, $blockToCreate, $projectArea, $newBlockGuid, $newBlockRMId);
my $dcIndex = createNewDCIndex($dcRmid, $dcGuid, $projectArea, $blockToCreate, $newBlockRMId); 

	#3. Add DC (part) right after the "Class" tag of the Parent Block 
my $newBlockDCAddedFileContents = insertChild($origFileContents, $dcEntry, $parentBlock, "IClass");
$origFileContents = $newBlockDCAddedFileContents;

	#4. Add DC GUID to the Parent Block's aggregations 
my $fileContentsWithDCBlockAgg =  aggregateBlock($parentBlock, $dcGuid, $origFileContents, "IClass");
$origFileContents = $fileContentsWithDCBlockAgg;

	#5. Add DC to RM Server index 
my $insertNewDCIndex = insertNewIndex($origFileContents, $dcIndex, $parentBlock);
 $origFileContents = $insertNewDCIndex;

	#6. Add DC RMId to Rhapsody indicies (to parent Block)
my $newdcIndexAlsoAppendedToParentBlock = appendNewBlockToPackageIndex($parentBlock, $dcRmid, $projectArea, $origFileContents);
$origFileContents = $newdcIndexAlsoAppendedToParentBlock;
 
my $trimmedFileContents = trimFileContents($origFileContents); 
$origFileContents = $trimmedFileContents;

#write to File... 
open (WR, '>', $fileName) or die "Cannot open file: $fileName";
# binmode WR;

my @contentArray = split(/\n/, $origFileContents);
foreach (@contentArray){
	chomp($_);
	print WR "$_\n"; 
}

close (WR);

fixRhapsodyIndicies($fileName);

print "Command completed successfully\nSetting Stereotype for Block: $blockToCreate\n";

my $setStereoTypeChildBlock = qx/perl 3-setStereotype.pl $blockToCreate $rhpProject/;

my $command = "perl 0-listBlocksBackgrd.pl " . $rhpProject; 

my $output = system($command . " > logFile.txt &");

print $setStereoTypeChildBlock;





