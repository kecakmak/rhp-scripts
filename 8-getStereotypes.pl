#!/usr/bin/perl

use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;

my $rhpProject = $ARGV[1];
my $stType = $ARGV[0];

#Linux
my $wsName = "WORKSPACE_" . $rhpProject; 
my $workspace = getEnvironments($wsName); 

my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 
my $rhpProjectFileName = "RHAPSODY_FILE_NAME_" . $rhpProject; 
my $rhpProjectFile = getEnvironments($rhpProjectFileName);

my $wsPath = getEnvironments("WORKSPACE");

my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);

my $fullPath = $workspace  . "\/" .  $rhapsody_file_dir;
my $searchPath = $fullPath ;

my $parentFolders = qx/find $fullPath \-type f \-exec grep \-H \'<_name type=\"a\">ST_Systems<\/_name>\' \{\} \\\;/;
my $parentFolder = findCorrectFileName($parentFolders, "ST_Systems");
my $fileContents = "";

open (READ_PRT, '<', $parentFolder) or die "Cannot open file $parentFolder"; 

while (<READ_PRT>){
	chomp($_);
	if ($fileContents eq "") {
		$fileContents = $_ . "\n";
	}
	else {
		$fileContents = $fileContents . $_ . "\n"; 
	}

}

close (READ_PRT);


# To find Stereotype first read the file 
my $projectFilePath = $workspace  . "\/" . $rhpProjectFile;

my $profileFile = "";
my $relProfileFile = "";
my $profilePath = findNVLProfilePath($projectFilePath); 

if ($profilePath eq "ERROR"){
	print "Stereotype profile File not found!! Exiting.... ";
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

print "$stType\n";
print "$profileFile\n";
my $profileContents = ""; 

open (READ_PROF, '<', $profileFile) or die "Cannot open file $profileFile"; 

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

#check if the given stereotype exists 

my $stExists = checkStereotype($profileContents, $stType); 

if ($stExists eq "false") {
	print "Given Stereotype: $stType doesn't exist. Please select correct Stereotype\n"; 
	exit -1;
	
}

# From this point below, the given stereotype exists.. 

# check if the Stereotype has children 
my $allChildren = printChildArr($profileContents, $stType); 

print $allChildren; 



sub printChildArr {
	my $Contents=$_[0];
	my $st = $_[1]; 
	my $child = ""; 
	my $hasChildren = checkChildren($Contents, $st); 

	if ($hasChildren eq "false") {
		print "$stType is leaf\n"; 
	} 

	else {
		print "$stType [ \n ";
		my @child_arr = split(/\,/, $hasChildren);



		foreach (@child_arr) {
			$_=~s/'//ig;
			if ($child eq "") {$child = $_;} 
			else {$child = $child . ", " . $_;}
		}
		$child = $child . "\n ]";


	}
	
	return $child; 
}



sub checkStereotype {

	my $fileContents = $_[0];
	my $stType = $_[1];
	
	my $result = "false"; 
	
	my @fileContents_arr = split(/\n/,$fileContents); 
	my $inSt = "false"; 
	
	
	foreach(@fileContents_arr) {
		chomp($_); 
		my $line = $_; 
		if (index($line, "<IStereotype type=\"e\">")!=-1) {$inSt = "true";} 
		if (index($line, "<\/IStereotype>")!=-1) {$inSt = "false";}
		
		if ($inSt eq "true") {
			if (index($line, "<_name type=\"a\">$stType<\/_name>")!=-1) {
				$result = "true";
				last;
			}
		}
	
	}
	
	return $result;  

}

sub checkChildren{ 

	my $fileContents = $_[0];
	my $stType = $_[1];
	
	my $result = "false"; 
	
	my @fileContents_arr = split(/\n/,$fileContents); 
	
	#STEP 1:  find the GUID of the stereotype
#EXAMPLE
#		<IStereotype type="e">
#			<_id type="a">GUID 1382418f-be7f-4146-bf65-ab4d91118b35</_id>
#			<_myState type="a">8192</_myState>
#			<_rmmServerID type="a">1293950_cImqIgkqEe21o7SZHKptFQ</_rmmServerID>
#			<_name type="a">2100_Dieselmotorenanlage</_name>


	my $stGuid = findGuid($stType, $fileContents, "IStereotype"); 

	# STEP 2: check if the GUID of the Stereotype exists in any Generalizations 
#EXAMPLE
#		<IGeneralization type="e">
#			<_id type="a">GUID 73ca7263-0338-4cdd-bacf-3ba4fb3d04d9</_id>
#			<_rmmServerID type="a">1293925_cImqIgkqEe21o7SZHKptFQ</_rmmServerID>
#			<_modifiedTimeWeak type="a">1.2.1990::0:0:0</_modifiedTimeWeak>
#			<_modifiedTime type="a">3.8.2022::12:3:50</_modifiedTime>
#			<_dependsOn type="r">
#				<INObjectHandle type="e">
#					<_hm2Class type="a">IStereotype</_hm2Class>
#					<_hid type="a">GUID 1382418f-be7f-4146-bf65-ab4d91118b35</_hid>
#					<_hrmmServerID type="a">1293950_cImqIgkqEe21o7SZHKptFQ</_hrmmServerID>
#				</INObjectHandle>
#			</_dependsOn>

	my $inGen = "false"; 
	my $inCorrectGen = "false"; 
	my $inInObjectHandle = "false";
	my $prospectGenGUID = "";
	my $genGUID = ""; 
	
	foreach (@fileContents_arr) {
		chomp($_); 
		my $line = $_; 
		if (index($line, "<IGeneralization type=\"e\">")!=-1) {$inGen = "true";}
		if (index($line, "<\/IGeneralization")!=-1) {
			$inGen = "false"; 
			$inCorrectGen = "false"; 
			$inInObjectHandle = "false";
		}
		
		
		if ($inGen eq "true") {
			if (index($line, "<_id type=\"a\">")!=-1){
				$line =~s/<_id type="a">//ig;
				$line =~s/<\/_id>//ig;
				$line =~s/\s//ig;
				$prospectGenGUID = $line; 
				next;

			}
			if (index($line, "<INObjectHandle")!=-1){$inInObjectHandle = "true";}
		
			if ($inInObjectHandle eq "true") {
				if (index($line, "<_hid type=\"a\">$stGuid")!=-1) {
					$prospectGenGUID =~s/GUID//ig;
					if ($genGUID eq "") {$genGUID = $prospectGenGUID;}
					else {$genGUID = $genGUID . "," . $prospectGenGUID;}
				}
			}
		}
	
	}
	
	if ($genGUID eq ""){
		$result = "false";
	}
	
	else{
	
	#STEP 3: check if any Stereotype has the GUID of the Generalizaton in their aggregate list 
	# those which have, are the children of the original Stereotype
#EXAMPLE
#		<IStereotype type="e">
#			<_id type="a">GUID dac86433-3f2b-4765-ae1c-2313db4de023</_id>
#			<_myState type="a">8192</_myState>
#			<_rmmServerID type="a">1293927_cImqIgkqEe21o7SZHKptFQ</_rmmServerID>
#			<_name type="a">2110_Stromerzeugungsaggregate_fuer_Antrieb_und_E_Erzeugung</_name>
#			<_modifiedTimeWeak type="a">3.4.2022::12:36:20</_modifiedTimeWeak>
#			<_modifiedTime type="a">10.12.2022::6:30:24</_modifiedTime>
#			<_m2Classes type="c">
#				<IRPYRawContainer type="e">
#				</IRPYRawContainer>
#			</_m2Classes>
#			<AggregatesList type="e">
#				<value>GUID 7aa66b9a-c93c-4918-9613-b9c6c669c18e</value>
#				<value>GUID 73ca7263-0338-4cdd-bacf-3ba4fb3d04d9</value>
#			</AggregatesList>
			
		my @genGUID_arr = split(/,/,$genGUID);
		
		my $childSt = "";
		
		foreach (@genGUID_arr) {
		
			$genGUID = $_;
		
			my $prospectChild = "";
			my $inSt = "false";
			my $inAggregateList = "false"; 
			foreach (@fileContents_arr) {
				chomp($_); 
				my $line = $_; 			
				if (index($line, "<IStereotype type=\"e\">")!=-1) {$inSt = "true";}
				if (index($line, "<\/IStereotype>")!=-1) {
					$inSt = "false"; 
					$inAggregateList = "false";
					$prospectChild = ""; 
				}

				if ($inSt eq "true") {
					if (index($line, "<_name type=")!=-1){
						$prospectChild = $line; 
						$prospectChild =~s/<_name type="a">//ig;
						$prospectChild =~s/<\/_name>//ig;
						$prospectChild =~s/\s//ig;
					}

					if (index($line, "<AggregatesList type")!=-1) {$inAggregateList = "true";} 
				}

				if ($inAggregateList eq "true") {
					if (index($line, $genGUID)!=-1){
						if ($childSt eq ""){$childSt = "'" . $prospectChild . "'";} 
						else {$childSt = $childSt . "," . "'" . $prospectChild . "'";} 
					}

				} 


			}
		}	

	$result = "$childSt";	
	}
			
	
	return $result;  


}

































