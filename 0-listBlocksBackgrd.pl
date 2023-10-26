#!/usr/bin/perl

use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;

my $rhpProject = $ARGV[0];

print "$rhpProject\n"; 

#Linux
my $wsName = "WORKSPACE_" . $rhpProject; 
my $workspace = getEnvironments($wsName); 

my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

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

my $stName = "";

my $childIDsOfParentPackage = findIDsOfParentPackage($fileContents);

my $rootBlocknID = nameOfTheBlockAndGUID($childIDsOfParentPackage,$fileContents);

my ($rootBlock,$rootID) = split("::",$rootBlocknID);

$rootID = "GUID " . $rootID;

my $parentBlock = $rootBlock; 

#find parts for the parent Block: 

my $childPartsNGUIDs = findPartsForTheParentBlock($fullPath, $rootID, $rootBlock);
my @parentBlocks_arr = ""; 

my @parts_arr = split(/\n/,$childPartsNGUIDs); 

my @parentBlocks_Arr = "";

foreach (@parts_arr){
	chomp($_);
	if ($_ eq ""){next;}
	my $childBlockNameAndGUIDs=getBlockInfoFromParts($fullPath, $_);
	push @parentBlocks_arr, $childBlockNameAndGUIDs;

}

open (BLLIST, '>', "blockList.json"); 

print BLLIST "\n[\n";

for (my $i = 0; $i <= $#parentBlocks_arr; $i++) {
	my $line = $parentBlocks_arr[$i]; 
	chomp ($line);
	if ($line eq "") {next;}
	my ($pBlockName, $pBlockGUID)=split(/::/,$line);

	
	my @L1Block_arr = ""; 

	my $tempParts = findPartsForTheParentBlock($fullPath, $pBlockGUID, $pBlockName);
	
	my @tempParts_arr = split(/\n/,$tempParts);
		
	foreach (@tempParts_arr) {
		chomp($_);
		if ($_ eq "") {next;} 
		my $line = $_; 
		
		my $tempBlockNameAndGUID = getBlockInfoFromParts($fullPath, $line);

		push @L1Block_arr,$tempBlockNameAndGUID;
			
	}


	print BLLIST "\t{\n\t\t'name':'$pBlockName',";
	$stName = findStereotype($fullPath, $pBlockName, $pBlockGUID);
	$stName=~s/\s//ig;
	print BLLIST "\n\t\t'stereotype':'$stName',";
	print BLLIST "\n\t\t'children':[";

	my $l1_arr = @L1Block_arr;
	
	@L1Block_arr=uniq(@L1Block_arr);
	
	if ($#L1Block_arr == 0){print BLLIST "]";}
	else {
	
		for (my $j = 0; $j <= $#L1Block_arr; $j++)  {
			my $line = $L1Block_arr[$j];
			chomp($line);
			if ($line eq "") {next;}
			my ($pBlockName, $pBlockGUID)=split(/::/,$line);
			print BLLIST "\n\t\t\t{";
			print BLLIST "\n\t\t\t\t'name':'$pBlockName',";
			$stName = findStereotype($fullPath, $pBlockName, $pBlockGUID);
			$stName=~s/\s//ig;
			print BLLIST "\n\t\t\t\t'stereotype':'$stName',";
			print BLLIST "\n\t\t\t\t'children':[";
			my @L2Block_arr = ""; 

			my $tempParts = findPartsForTheParentBlock($fullPath, $pBlockGUID, $pBlockName);

			my @tempParts_arr = split(/\n/,$tempParts);

			foreach (@tempParts_arr) {
				chomp($_);
				if ($_ eq "") {next;} 
				my $line = $_; 

				my $tempBlockNameAndGUID = getBlockInfoFromParts($fullPath, $line);

				push @L2Block_arr,$tempBlockNameAndGUID;

			}
			
			@L2Block_arr=uniq(@L2Block_arr);

			if ($#L2Block_arr == 0){print BLLIST "]";}
			else {

				for (my $k = 0 ; $k <= $#L2Block_arr; $k++){
					my $line = $L2Block_arr[$k]; 
					chomp($line);
					if ($line eq "") {next;} 
					print BLLIST "\n\t\t\t\t\t{";
					my ($pBlockName, $pBlockGUID)=split(/::/,$line);
					print BLLIST "\n\t\t\t\t\t\t'name':'$pBlockName',";
					$stName = findStereotype($fullPath, $pBlockName, $pBlockGUID);
					$stName=~s/\s//ig;
					print BLLIST "\n\t\t\t\t\t\t'stereotype':'$stName',";
					print BLLIST "\n\t\t\t\t\t\t'children':[";

					my @L3Block_arr = ""; 

					my $tempParts = findPartsForTheParentBlock($fullPath, $pBlockGUID, $pBlockName);

					my @tempParts_arr = split(/\n/,$tempParts);

					foreach (@tempParts_arr) {
						chomp($_);
						if ($_ eq "") {next;} 
						my $line = $_; 

						my $tempBlockNameAndGUID = getBlockInfoFromParts($fullPath, $line);

						push @L3Block_arr,$tempBlockNameAndGUID;

					}
					
					@L3Block_arr=uniq(@L3Block_arr);
					
					if ($#L3Block_arr == 0){print BLLIST "]";}
					
					else {


						foreach (my $l = 0; $l<= $#L3Block_arr; $l++){
							my $line = $L3Block_arr[$l];
							chomp($line);
							if ($line eq "") {next;} 
							print BLLIST "\n\t\t\t\t\t\t\t{";
							my ($pBlockName, $pBlockGUID)=split(/::/,$line);
							if ($l < $#L3Block_arr) {
								print BLLIST "\n\t\t\t\t\t\t\t\t'name':'$pBlockName',";				
							}
							else {
								print BLLIST "\n\t\t\t\t\t\t\t\t'name':'$pBlockName',";
							}
							$stName = findStereotype($fullPath, $pBlockName, $pBlockGUID);
							$stName=~s/\s//ig;
							print BLLIST "\n\t\t\t\t\t\t\t\t'stereotype':'$stName',";	
							print BLLIST "\n\t\t\t\t\t\t\t\t'children':[]";
							if ($l < $#L3Block_arr) {print BLLIST "\n\t\t\t\t\t\t\t},";}
							else {print BLLIST "\n\t\t\t\t\t\t\t}";}
						}
					print BLLIST "\n\t\t\t\t\t\t]";

				}
				if ($k < $#L2Block_arr) {print BLLIST "\n\t\t\t\t\t},";}
				else {print BLLIST "\n\t\t\t\t\t}";}
			}
			print BLLIST "\n\t\t\t\t]";
		}

		if ($j < $#L1Block_arr) {print BLLIST "\n\t\t\t},";}	
		else {print BLLIST "\n\t\t\t}"};
		}
		print BLLIST "\n\t\t]";
	}


if ($i < $#parentBlocks_arr) {print BLLIST "\n\t},\n";}
else {print BLLIST "\n\t}";}

}

print BLLIST "\n]";	
close(BLLIST);

exit (-1);

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub  getBlockInfoFromParts {
	my $fullPath = $_[0];
	my $input = $_[1];
	my ($levelPartName,$levelPartGUID) = split("::",$input);
	
	$levelPartGUID = "GUID " . $levelPartGUID;
	my $blockFiles = qx/ find $fullPath \-type f  \| xargs -n1 awk \'\/<_id type=\"a\">$levelPartGUID<\\\/_id>\/\,\/<_name type=\"a\">$levelPartName<\\\/_name>\/ \{printf FILENAME \"  \"\; print\}\'  / ;
	$levelPartGUID =~s/GUID //ig;
	$blockFiles=~s/\t/:/ig;
		
	my ($blockFile,$junk) = split(":::",$blockFiles);
	$blockFile=~ s/\s+$//; #right trim to get rid of any spaces at the end 
	$fileContents = getFileContents($blockFile);
	my $levelBlockNameAndGUID = findBlockIDandNameFromPart($levelPartGUID, $fileContents); 
	
	return $levelBlockNameAndGUID;
}

sub findPartsForTheParentBlock {

	my $fullPath = $_[0];
	my $rootID = $_[1];
	my $rootBlock = $_[2]; 

	my $partFiles = qx/ find $fullPath \-type f  \| xargs -n1 awk \'\/<_id type=\"a\">$rootID<\\\/_id>\/\,\/<_name type=\"a\">$rootBlock<\\\/_name>\/ \{printf FILENAME \"  \"\; print\}\'  / ;
	$partFiles=~s/\t/:/ig;
	my ($partFile,$junk) = split(":::",$partFiles);
	$partFile=~ s/\s+$//; #right trim to get rid of any spaces at the end 
	$fileContents = getFileContents($partFile);
	
	my $childIDs = findIDsOfParentBlock($fileContents, $rootID);
	my $childPartsNGUIDs = nameOfThePartAndGUID($childIDs,$fileContents);
	
	
	
	return $childPartsNGUIDs; 
}



sub findBlockIDandNameFromPart {

	my $levelXPartGUID ="";
	$levelXPartGUID = $_[0]; 
	my $fileContents = $_[1];
	my $inClass = "false";
	my $inRootClass = "false";
	my $inParentClass = "false";

	my @fileContents_arr = split("\n",$fileContents); 
	my $retVal = ""; 
	my $parentClassName="";
	my $parentClassID="";

	if ($levelXPartGUID ne ""){


		foreach(@fileContents_arr) {
			chomp($_);
			my $line = $_; 
			if (index($line, "<IPart type=\"e\">")!=-1){$inClass="true"}
			if (index($line, "<\/IPart>") !=-1) {
				$inClass = "false";
				$inRootClass = "false"; 
				$inParentClass = "false";
			}

			if ($inClass eq "true") {
				if (index($line,"<_id type=\"a\">GUID " .  $levelXPartGUID . "<\/_id>")!=-1){
					$inRootClass = "true"; 
				}
			}

			if ($inRootClass eq "true"){
				if (index($line,"<_otherClass type=\"r\">")!=-1){$inParentClass = "true";}
			}
			if (index($line,"<\/_otherClass>")!=-1){$inParentClass="false";}

			if ($inParentClass eq "true") {
				if (index($line,"<_hname type=\"a\">")!=-1){
					$line =~s/<_hname type=\"a\">//ig;
					$line =~s/<\/_hname>//ig;
					$line =~s/\t//ig;
					$parentClassName = $line;
				}
				if (index($line,"<_hid type=\"a\">")!=-1){
					$line =~s/<_hid type=\"a\">//ig;
					$line =~s/<\/_hid>//ig;
					$line =~s/\t//ig;
					$parentClassID = $line;
					if ($parentClassName eq "") {
						$parentClassName = findNameByGUID($parentClassID,$fileContents,"IClass");
					}
				}	
			}

		}
	
	}
	$retVal = $parentClassName . "::" . $parentClassID;
	

}




sub nameOfThePartAndGUID {
	
	$childIDsOfParentPackage=$_[0];
	$fileContents = $_[1];

	my @childIDsArr = split("::",$childIDsOfParentPackage); 
	my @fileContentArr = split("\n",$fileContents);
	my $retVal = ""; 
	foreach (@childIDsArr) {


		chomp($_);
		my $childID = $_; 
		
		my $inClass = "false";
		my $inRootClass = "false";
		my $inAggregateList = "false";

		my $isSepFile = "false"; 
		my $inClassIsFileName="false"; 
		my $prospectRetVal = ""; 

		
		foreach (@fileContentArr) {
			chomp($_);
			my $line = $_;
			
			if (index($line, "<IPart type=\"e\">") !=-1 ) {$inClass = "true";}
			if (index($line, "<\/IPart>") !=-1) {
				$inClass = "false";
				$inRootClass = "false";
				$inClassIsFileName = "false";
			}
			
			if ($inClass eq "true") {
				if (index($line,"<_id type=\"a\">GUID ".  $childID . "<\/_id>")!=-1){
					$inRootClass = "true"; 
				}
				
				if (index($line,"<fileName>")!=-1) {
					$inClassIsFileName = "true"; 
					$line =~s/\t//ig;
					$line=~s/<fileName>//ig;
					$line=~s/<\/fileName>//ig;
					$prospectRetVal = $line; 
				}
				
				if ($prospectRetVal ne "") {
					if (index($line,"<_id type=\"a\">GUID " . $childID . "<\/_id>")!=-1) {
						my $blockName = $prospectRetVal; 
						$prospectRetVal = "";
							
						if (index($retVal,$childID)!=-1){next;}

						$retVal = $retVal . "\n" . $blockName . "::" . $childID;

					}
				}
				
			}

			if ($inRootClass eq "true") {
				if (index($line, "<_name type=\"a\">")!=-1) {
					# not seperate file 

					$line =~s/\t//ig;
					$line =~s/<_name type=\"a\">//ig;
					$line =~s/<\/_name>//ig;
					my $blockName = $line;
					
					if ($retVal ne "TopLevel") {
					
					if (index($retVal,$childID)!=-1){next;}
					
						$retVal = $retVal . "\n" . $blockName . "::" . $childID;

					}
					else {$retVal = "";} 
				}
			
				
			}


		}
		


	}
	
	return $retVal;
	
}



sub nameOfTheBlockAndGUID {
	
	my $childIDsOfParentPackage=$_[0];
	$fileContents = $_[1];

	my @childIDsArr = split("::",$childIDsOfParentPackage); 
	my @fileContentArr = split("\n",$fileContents);
	my $retVal = ""; 
	foreach (@childIDsArr) {


		chomp($_);
		my $childID = $_; 
		
		my $inClass = "false";
		my $inRootClass = "false";
		my $inAggregateList = "false";

		my $isSepFile = "false"; 
		my $inClassIsFileName="false"; 
		my $prospectRetVal = ""; 

		
		foreach (@fileContentArr) {
			chomp($_);
			my $line = $_;
			
			if (index($line, "<IClass type=\"e\">") !=-1 ) {$inClass = "true";}
			if (index($line, "<\/IClass>") !=-1) {
				$inClass = "false";
				$inRootClass = "false";
				$inClassIsFileName = "false";
			}
			
			if ($inClass eq "true") {
				if (index($line,"<_id type=\"a\">GUID ".  $childID . "<\/_id>")!=-1){
					$inRootClass = "true"; 
				}
				
				if (index($line,"<fileName>")!=-1) {
					$inClassIsFileName = "true"; 
					$line =~s/\t//ig;
					$line=~s/<fileName>//ig;
					$line=~s/<\/fileName>//ig;
					$prospectRetVal = $line; 
				}
				
				if ($prospectRetVal ne "") {
					if (index($line,"<_id type=\"a\">GUID " . $childID . "<\/_id>")!=-1) {
						$retVal = $prospectRetVal; 
						$prospectRetVal = "";
	
						if (index($retVal,$childID)!=-1) {next;}
						
						$retVal = $retVal . "::" . $childID;
#						return $retVal;
#						exit (-1); 
					}
				}
				
			}

			if ($inRootClass eq "true") {
				if (index($line, "<_name type=\"a\">")!=-1) {
					# not seperate file 
					$retVal = $line;
					$retVal =~s/\t//ig;
					$retVal =~s/<_name type=\"a\">//ig;
					$retVal =~s/<\/_name>//ig;
					
					if (index($retVal,$childID)!=-1) {next;}

					if ($retVal ne "TopLevel") {
						$retVal = $retVal . "::" . $childID;
#						return $retVal;
#						exit (-1);
					}
					else {$retVal = "";} 
				}				
			}


		}
		


	}
	
	return $retVal;
	
}




sub findIDsOfParentPackage {

	$fileContents = $_[0];

	my $name="";

	my @fileCont_arr=split(/\n/,$fileContents);
	my $inParentPackage = "false";
	my $inAggregateList = "false";

	my $retVal="";
	foreach(@fileCont_arr) {

		chomp($_);
		my $line = $_; 
	

		if (index($line, "<_name type=\"a\">ST_Systems<\/_name>") !=-1 ) {$inParentPackage = "true";}
		if (index($line, "<\/ISubsystem>") !=-1) {
			$inParentPackage = "false";
			$inAggregateList = "false";
		} 
		
		


		if ($inParentPackage eq "true") {
			if (index($line,"<AggregatesList type=\"e\">")!=-1) {$inAggregateList = "true";}
		}

		if ($inAggregateList eq "true") {
			if (index($line,"<value>")!=-1) {
				$line =~ s/\t//ig;
				$line =~ s/<value>//ig;
				$line =~ s/<\/value>//ig;
				$line =~ s/GUID //ig;
				
				if (index($retVal, $line)!=-1){next;}
				
				else{
				
					if ($retVal eq "") {
						$retVal = $line;
					}
					else{
						$retVal = $retVal . "::" . $line;
					}
				}
			}
		}

	}
	
	return $retVal;



}

sub findStereotype { 


	my $fullPath = $_[0];
	my $rootID = $_[2];
	my $rootBlock = $_[1]; 

	my $partFiles = qx/ find $fullPath \-type f  \| xargs -n1 awk \'\/<_id type=\"a\">$rootID<\\\/_id>\/\,\/<_name type=\"a\">$rootBlock<\\\/_name>\/ \{printf FILENAME \"  \"\; print\}\'  / ;
	$partFiles=~s/\t/:/ig;
	my ($partFile,$junk) = split(":::",$partFiles);
	$partFile=~ s/\s+$//; #right trim to get rid of any spaces at the end 
	$fileContents = getFileContents($partFile);
	
	my @fileContents_arr = split(/\n/,$fileContents); 
	
	my $inHandle = "false"; 
	my $inStereotype = "false"; 
	my $inMBGrV = "false"; 
	my $stName = "";
	my $inClass = "false";
	my $inCorrectClass = "false"; 
	
	
	foreach(@fileContents_arr) {
		chomp($_);
		my $line = $_; 
		
		if (index($line,"<IClass type=\"e\">")!=-1) {
			$inClass = "true"; 
		}
		if (index($line, "<\/IClass>") !=-1) {
			$inClass = "false";
			$inCorrectClass = "false";
		}
		
		if ($inClass eq "true") { 
			if (index($line,"<_id type=\"a\">$rootID")!=-1) {$inCorrectClass = "true";} 
		}
		
		if ($inCorrectClass eq "true") {
			if (index($line, "<IHandle") !=-1) {$inHandle = "true";}
				if (index($line, "<\/IHandle")!=-1) {
					$inHandle = "false"; 
					$inStereotype = "false"; 
					$inMBGrV = "false"; 
				}
			
				if ($inHandle eq "true") {
			
					if (index($line,"<_hm2Class type=\"a\">IStereotype")!=-1){$inStereotype = "true";} 
					if ($inStereotype eq "true") {
						if ((index($line, "MBGrV")!=-1) && (index($line,"<_hsubsystem ")!=-1)){$inMBGrV = "true";} 
					}
					if ($inMBGrV eq "true"){
						if(index($line,"<_hname")!=-1){
							$stName = $line;
							$stName =~s/<_hname type=\"a\">//ig;
							$stName =~s/<\/_hname>//ig;
						}
					}
				
				
				}			
		
		}
	
	}
	return $stName; 
			

}




exit -1;

