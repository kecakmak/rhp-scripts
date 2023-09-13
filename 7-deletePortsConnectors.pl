

#!/usr/bin/perl

#use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;



# inputs
my $arguments = $ARGV[0];
my ($partToDelete, $portToDelete, $connectorRequested, $rhpProject) = split("::",$arguments); 
my $connectorToDelete = "";
my $connectorToDeleteID = "";
my $otherPart = ".";

if ($rhpProject eq "NULL") {

	print "\n \nPlease enter a valid Rhapsody Project Name\n";
	print "Usage: 7-deletePortsConnectors <Item to Delete> <Rhapsody Project Name>\n"; 
	exit -1; 
}


if (($partToDelete eq "NULL") || ($partToDelete eq ""))  {

	print "\n \nMissing Part Name to delete\n";
	print "Usage: \n"; 
	print "1. To delete a Part (Block) with all its ports and connectors, \n"; 
	print "perl 7-deletePortsConnectors <Part Name to Delete> <Rhapsody Project Name>\n\n"; 
	print "2. To delete a Port of a specific Block, with all its connectors, \n"; 
	print "perl 7-deletePortsConnectors <Part Name> <Port Name to Delete> <Rhapsody Project Name>\n\n"; 
	print "3. To delete a Connector of a specific Port or a specific Block\n"; 
	print "perl 7-deletePortsConnectors <Part Name> <Port Name> <Connector Name to Delete> <Rhapsody Project Name>\n\n"; 
	exit -1; 
}


my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);

my $fullPath = $workspace  . "\/" .  $rhapsody_file_dir;
my $searchPath = $fullPath ;



if (($partToDelete ne "") && ($partToDelete ne "NULL")){

	my $portsAll = justListPorts($partToDelete,$searchPath);

	my ($parentFromBlockandPart, $fromPorts) = split(/==/,$portsAll);
	my ($parentFromBlockPart_all,$parentFromBlock) = split("-OFPART-",$parentFromBlockandPart);
	my ($parentFromBlockID, $parentFromBlockPart) = split("PARTBLOCK_SEPERATOR", $parentFromBlockPart_all);

	my @portNames_arr = split(/::/,$fromPorts);

	my $portCheck = "false";

	if (($portToDelete ne "") || ($portToDelete ne "NULL")){
		my $fromPortID_all = ""; 
		my $fromPortRMID = "";
		my $fromPortID = "";
		my $fromPortName = ""; 

		for (@portNames_arr) {
			my $portNameAndID = $_;
    		if (grep(/$portToDelete/, $portNameAndID )) {
       		$portCheck = "true";
			($fromPortName, $fromPortID_all) = split(/\|\|/, $portNameAndID);
			($fromPortID, $fromPortRMID) = split("RM_SEPERATOR", $fromPortID_all);
       		last;
    		}
		}
		
		if ($portCheck eq "true"){
			if (($connectorRequested eq "") || ($connectorRequested eq "NULL")){
				print "all connectors of this port and also the port itself: $portToDelete will be deleted\n"; 
				deletePort($fullPath, $portToDelete, $fromPortID, $parentFromBlockID);
			}
			else {
				my $connectorOfPort = getConnectorOfPort($fullPath, $fromPortName, $fromPortID, $parentFromBlockPart, $parentFromBlock, $otherPart);
				if (grep(/$connectorRequested/, $connectorOfPort )) {
					my @connectorInfo_arr = split(/\|\|/,$connectorOfPort);
						for (@connectorInfo_arr) {
							my ($tempConnectorName,$tempConnectorID) = split("ID_SEPERATORGUID", $_);
							if ($tempConnectorName eq $connectorRequested) {
								$connectorToDelete = $tempConnectorName;
								$connectorToDeleteID = $tempConnectorID;
								
							}
						}
					print "Deleting Connector: $connectorToDelete\n$connectorToDeleteID\n";
					
					deleteConnector($fullPath, $connectorToDelete, $connectorToDeleteID, "b", "x");
				}
				else {
					print "Wrong Connector Name Provided\n";
				}

			}
		}
		else {
			print "Wrong Port Name Provided\n";
		}
	
	}

}


else {
	print "\n \nMissing Part Name to delete\n";
	print "Usage: \n"; 
	print "1. To delete a Part (Block) with all its ports and connectors, \n"; 
	print "perl 7-deletePortsConnectors <Part Name to Delete> <Rhapsody Project Name>\n\n"; 
	print "2. To delete a Port of a specific Block, with all its connectors, \n"; 
	print "perl 7-deletePortsConnectors <Part Name> <Port Name to Delete> <Rhapsody Project Name>\n\n"; 
	print "3. To delete a Connector of a specific Port or a specific Block\n"; 
	print "perl 7-deletePortsConnectors <Part Name> <Port Name> <Connector Name to Delete> <Rhapsody Project Name>\n\n"; 
	exit -1; 
}


sub justListPorts{
	my $fromPartFileContents = "";
	my $fromPartName = $_[0];
	my $searchPath = $_[1];
		
	my $fromPartFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$fromPartName\' \{\} \\\;/;
		
	my $fromPartFileName = findCorrectFileName($fromPartFileNames, $fromPartName); 

	if ($fromPartFileName eq "ERROR") {
		print "\nERROR: Cannot find provided parts: $fromPartName... Check if the part names provided are true\n";
		exit -1;
	}
		
	open (READ_PRT, '<', $fromPartFileName) or die "Cannot open file: $fromPartFileName";

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

	my $fromPartGUID = findGuid($fromPartName, $fromPartFileContents, "IPart");
	my $fromPartRMID = findRmid($fromPartName, $fromPartFileContents, "IPart");

	if (($fromPartGUID eq "ERROR") or ($fromPartRMID eq "ERROR")) {
		print "\nERROR: Cannot find provided part $fromPartName... Check if the part names provided are true\n";
		exit -1;
	}
	
	
	my $fromBlockName = getBlockName($fromPartName, $fromPartFileContents, "IPart"); 

	my $parentFromBlock = findParentName($fromPartGUID, $fromPartFileContents, "IClass");
	
	if ($parentFromBlock eq "ERROR") {
		print "\nERROR: Cannot find a parent Block for the provided part $fromPartName... Check if the part names provided are true2\n";
		exit -1;
	}
	
	my $fromBlockFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$fromBlockName\' \{\} \\\;/;
	my $fromBlockFileName = findCorrectFileName($fromBlockFileNames, $fromBlockName);
	
	
	if ($fromBlockFileName eq "ERROR") {
		print "\nERROR: Cannot find main blocks for the provided ports ... Check if the port names provided are true\n";
		exit -1;
	}	
	my $fromBlockFileContents = "";
	if ($fromBlockFileName eq $fromPartFileName) {$fromBlockFileContents = $fromPartFileContents;}
	else { 
		open (READ_PRT, '<', $fromBlockFileName) or die "Cannot open file: $fromBlockFileName";

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
	
	
	my $fromBlockGUID = findGuid($fromBlockName, $fromBlockFileContents, "IClass");	
	my $childIDs = findIDsOfParentBlock($fromBlockFileContents, $fromBlockGUID);
	
	my @childIDs_arr = split(/::/,$childIDs);
	my $portList = "";

	foreach(@childIDs_arr){
		chomp($_);
		if ($_ eq "") {next;} 
		my $id = $_; 
		$id = "GUID " . $id;
		my $name = findNameByGUID($id,$fromBlockFileContents,"IPort"); 	
		my $rmID = findRmid($name, $fromBlockFileContents, "IPort");
		if ($name ne "") {
			if ($portList eq "") {$portList = $name . "||" . $id . "RM_SEPERATOR" . $rmID;} 
			else {$portList = $portList . "::" . $name . "||" . $id . "RM_SEPERATOR" . $rmID;} 
		}
	}
	
	$portList = $fromBlockGUID . "PARTBLOCK_SEPERATOR" . $fromPartGUID . "-OFPART-" . $parentFromBlock . "==" . $portList;
	print "$portList\n";
	return $portList;
	

}








sub deletePort {
	my $fullPath = $_[0];
	my $portName = $_[1]; 
	my $allID = $_[2];
	my $parentBlockPartID = $_[3];
#	my $parentBlockName = $_[4];
	
	print "\n\n\n$fullPath\n$portName\n$allID\n$parentBlockPartID\n";

}




sub deleteConnector { 
	my $fullPath = $_[0];
	my $portName = $_[1]; 
	my $allID = $_[2];
	my $parentBlockPartID = $_[3];
	my $parentBlockName = $_[4];
	
	my ($portID, $rmID) = split("RM_SEPERATOR", $allID);
	
	$portID = "GUID " . $portID;
		
	my $blockFiles = qx/ find $fullPath \-type f  \| xargs -n1 awk \'\/<_id type=\"a\">$portID<\\\/_id>\/\,\/<\\\/IObjectLink>\/ \{printf FILENAME \"  \"\; print\}\'  / ;
	$blockFiles=~s/\t/:/ig;
	
	my ($blockFile,$junk) = split(":::",$blockFiles);
	($blockFile,$junk) = split("::",$blockFiles); #sometimes there are 3 spaces, sometimes two... 
	$blockFile=~s/\s+$//; #right trim to get rid of any spaces at the end 
	
	print "Filename: $blockFile\n";
	
	if ($blockFile eq "") {
		print "Error with the connection information. Please make sure to use correct connection name for the given part and port\n";
		exit (-1);
	}
	
	my $fileContents = getFileContents($blockFile);
	my @fileContents_arr = split("\n",$fileContents);
	my $inConnector = "false"; 
	my $inCorrectConnector = "false";
	my $inElement = "false";
	my $inCorrectElement = "false";
	
	open(BUFFERINIT, ">",$blockFile);
	print BUFFERINIT "";
	close(BUFFERINIT);
	
	open(BUFFER, ">>", $blockFile); 
	
	foreach (@fileContents_arr) {
		chomp($_);
		my $line = $_; 
		if (index($line,"<IObjectLink type=\"e\">")!=-1) {$inConnector = "true";}
		if (index($line,"<ELEMENT>")!=-1){$inElement = "true";}
		if (index($line,"<\/IObjectLink>")!=-1){
			$inConnector = "false";
			$inCorrectConnector = "false";
		}
		if (index($line,"<\/ELEMENT")!=-1){
			$inElement = "false";
			$inCorrectElement = "false";
		}
		
		if (($inConnector eq "false") && ($inElement eq "false")) {
			print BUFFER $line . "\n"; 			
		}
		
		else {
# in Connector lets check if that is the right one. 
			if (index($line,"<_id type=\"a\">$portID")!=-1){
				$inCorrectConnector = "true"; 
			}
			
			if (index($line, "<ID>$rmID</ID>")!=-1){
				$inCorrectElement = "true";
			}

			if (($inCorrectConnector eq "true") || ($inCorrectElement eq "true")) {
				next;
			}
			else {
				print BUFFER $line . "\n";
			}
		}
	
	}
	close (BUFFER); 	


	my $fileContents = getFileContents($blockFile);
	my @fileContents_arr = split("\n",$fileContents);
	
	open (BUFFERR, ">", $blockFile);
	my $prev_line = "";
	my $prev_line_print = "";
	my $rm_prev_line = "";
	my $rm_prev_line_print = "";
	my $secSkip = "false";
	foreach(@fileContents_arr) {
	
		my $current_line = $_; 	
		chomp($current_line);
		$current_line =~s/\s//ig; 
		$current_line =~s/\n//ig;
		
		if (index($current_line,"<IObjectLinktype=\"e\">") !=-1) {
			$prev_line = $current_line;
			$prev_line_print = $_;
			next;
		}
		if ($prev_line ne "") {
			if (index($prev_line . $current_line,"<IObjectLinktype=\"e\"><\/IObjectLink>") !=-1){
				$prev_line = "";
				$prev_line_print = ""; 
				next;
			}
			else {
				print BUFFERR "$prev_line_print\n";
				$prev_line = "";
				$prev_line_print = ""; 
				}
		}
		
		
		if (index($current_line,"<ELEMENT>") !=-1) {
			$rm_prev_line = $current_line;
			$rm_prev_line_print = $_;
			next;
		}
		if ($rm_prev_line ne "") {
		print "$rm_prev_line" . "$current_line\n";
			if (index($rm_prev_line . $current_line,"<ELEMENT><\/REFERENCES>") !=-1){
				$rm_prev_line = "";
				$rm_prev_line_print = ""; 
				next;
			}
			else {
				print BUFFERR "$rm_prev_line_print\n";
				$rm_prev_line = "";
				$rm_prev_line_print = ""; 
				}
		}
		
	

		print BUFFERR "$_\n";

	}	
	close (BUFFERR);
	
	
	fixRhapsodyIndicies($blockFile);


}


sub getConnectorOfPort{
	my $fullPath = $_[0];
	my $portName = $_[1]; 
	my $portID = $_[2];
	my $parentBlockPartID = $_[3];
	my $parentBlockName = $_[4];

	my $printConnectors = printPortConnectors($fullPath,$portName,$portID,$parentBlockPartID,$parentBlockName);
	
	my @connector_arr = split("CONN_ARR_SEPERATOR", $printConnectors); 
	my $conn_arr_count = @connector_arr; 
	
	for (my $a=0; $a<$conn_arr_count; $a++){
		my $connector = $connector_arr[$a]; 
		chomp($connector);
		return $connector;
		
	}
	
}


sub printPortConnectors{
	my $fullPath = $_[0];
	my $portName = $_[1]; 
	my $portID = $_[2];
	my $parentBlockPartID = $_[3];
	my $parentBlockName = $_[4];
	
	my $blockFiles = qx/ find $fullPath \-type f  \| xargs -n1 awk \'\/<value>$parentBlockPartID<\\\/value>\/\,\/<_name type=\"a\">$parentBlockName<\\\/_name>\/ \{printf FILENAME \"  \"\; print\}\'  / ;
	$blockFiles=~s/\t/:/ig;
#Added in 03.08.2023 due to query reports space instead of tabs 
	$blockFiles=~s/\s/:/ig;

		
	my ($blockFile,$junk) = split(":::",$blockFiles);
	($blockFile,$junk) = split("::",$blockFiles); #sometimes there are 3 spaces, sometimes two... 
	$blockFile=~s/\s+$//; #right trim to get rid of any spaces at the end 
#	my $fileContents = getFileContents($blockFile);
	
	my $connectorInfo = getConnectorFiles($fullPath,$portID); 
	return $connectorInfo;

	
}


sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub getConnectorFiles{ 
	my $fullPath = $_[0];
	my $portID = $_[1];
	my $connectionString = ""; 
	my $connectionElement = "";
	my $connectionElements = "";
	
	my $blockFiles = qx/find $searchPath \-type f \-exec grep \-H \'<IObjectLink type=\"e\">\' \{\} \\\;/;
	my @blockFiles_Arr = split("\n",$blockFiles); 
	my @fileListArr = ""; 
	
	foreach(@blockFiles_Arr) {
		chomp($_); 
		my($fileNames,$junk) = split("\t",$_);
		$fileNames=~s/://ig;
		if ($fileNames ne ""){push(@fileListArr,$fileNames);}
	}
	my @fileListArrUn= uniq(@fileListArr);
	my $numOfFiles = @fileListArrUn;
	
	for (my $k=0; $k<$numOfFiles; $k++){
	
		my $item = $fileListArrUn[$k];
		next if ($item eq "");
		my $fileContents = getFileContents($item); 
		my $connectorInfo = getConnectorAndParts($fileContents,$portID); 
		my @connectorInfo_arr = split("ARRAY_SEPERATOR",$connectorInfo);
		my $number = @connectorInfo_arr; 


		for (my $j = 0; $j < $number; $j++) {
			my $item = $connectorInfo_arr[$j];
			my $connector1 = "";
			my $connector2 = ""; 
			my $connector = "";
			my ($connectorName, $connectorPart1, $connectorPart2) = split("CONNECTOR_SEPERATOR",$item);
			my ($connectorPartName1,$connectorDir1)=split(":::",$connectorPart1);		
			my ($connectorPartName2,$connectorDir2)=split(":::",$connectorPart2);	
			if ($otherPart eq "."){
				$connector1 = $connectorPartName1;
				$connector2 = $connectorPartName2; 
				$connector = $connectorName; 	
			}
			
			$connectionElement = "$connector";

			if ($connectionElements eq ""){$connectionElements = $connectionElement;}
			else {$connectionElements = $connectionElements . "||" . $connectionElement;}

		}


	}

	return $connectionElements; 
}

sub getConnectorAndParts{ 
	my $fileContents = $_[0];
	my $portID = $_[1];
	my @fileContent_arr = split("\n",$fileContents);
	my $inConnector = "false"; 
	my $inToLink = "false";
	my $inFromLink = "false";
	my $inToPort = "false";
	my $inFromPort = "false";
	my $prospectToPart = "";
	my $prospectFromPart = "";
	my $prospectConnectorName = ""; 
	my $prospectConnectorID = "";
	my $prospectConnectorRMID = ""; 
	my $connectionString = ""; 
	my $fromPart = "";
	my $toPart = ""; 
	my $returnValue = ""; 
	
	foreach (@fileContent_arr) {
		chomp($_); 
		if (index($_,"<IObjectLink type=\"e\">")!=-1) {$inConnector = "true";}
		if (index($_,"<\/IObjectLink>")!=-1){
			$inConnector = "false";
			$inToLink = "false"; 
			$inFromLink = "false"; 
			$inToPort = "false";
			$inFromPort = "false";
			$prospectToPart = ""; 
			$prospectFromPart = ""; 
			$prospectConnectorName = ""; 
			$prospectConnectorID = "";
			$prospectConnectorRMID = "";
		}
		
		if ($inConnector eq "true"){
		
			if (index($_,"<_name type=\"a\">")!=-1){
				$prospectConnectorName = $_; 
				$prospectConnectorName =~s/<_name type=\"a\">//ig;
				$prospectConnectorName =~s/<\/_name>//ig;
				$prospectConnectorName =~s/\s//ig;
			}
			
			if (index($_,"<_id type=\"a\">")!=-1){
				$prospectConnectorID = $_; 
				$prospectConnectorID =~s/<_id type=\"a\">//ig;
				$prospectConnectorID =~s/<\/_id>//ig;
				$prospectConnectorID =~s/\s//ig;
			}
			
			if (index($_,"<_rmmServerID type=\"a\">")!=-1){
				$prospectConnectorRMID = $_; 
				$prospectConnectorRMID =~s/<_rmmServerID type=\"a\">//ig;
				$prospectConnectorRMID =~s/<\/_rmmServerID>//ig;
				$prospectConnectorRMID =~s/\s//ig;
			}

		
			if (index($_,"<_toLink type=\"r\">")!=-1) {$inToLink = "true";}
			if (index($_,"</\_toLink>")!=-1) {
				$inToLink = "false";
			}
			if (index($_,"<_fromLink type=\"r\">")!=-1) {$inFromLink = "true";}
			if (index($_,"</\_fromLink>")!=-1) {
				$inFromLink = "false";
			}
			
			if ($inToLink eq "true") {
					if (index($_,"<_hname type=\"a\">")!=-1){
						$prospectToPart = $_; 
						$prospectToPart =~s/<_hname type=\"a\">//ig;
						$prospectToPart =~s/<\/_hname>//ig;
						$prospectToPart =~s/\t//ig;
					}
				
					
					if (($prospectToPart eq "") && (index($_,"<_hid type=\"a\">")!=-1)) {
						my $prospectToPartID = $_; 
						$prospectToPartID =~s/<_hid type=\"a\">//ig;
						$prospectToPartID =~s/<\/_hid>//ig;
						$prospectToPartID =~s/\t//ig;
						$prospectToPart = findNameByGUID($prospectToPartID, $fileContents, "IPart");
					}
					

		
				
			}
			
			if ($inFromLink eq "true") {
				if (index($_,"<_hid type=\"a\">")!=-1) {
					if (index($_,"<_hname type=\"a\">")!=-1){
						$prospectFromPart = $_; 
						$prospectFromPart =~s/<_hname type=\"a\">//ig;
						$prospectFromPart =~s/<\/_hname>//ig;
						$prospectFromPart =~s/\t//ig;
					}
					if (($prospectFromPart eq "") && (index($_,"<_hid type=\"a\">")!=-1)) {
						my $prospectFromPartID = $_; 
						$prospectFromPartID =~s/<_hid type=\"a\">//ig;
						$prospectFromPartID =~s/<\/_hid>//ig;
						$prospectFromPartID =~s/\t//ig;
						$prospectFromPart = findNameByGUID($prospectFromPartID, $fileContents, "IPart");
					}
				}
			}
			
			if (index($_,"<_toPort type=\"r\">")!=-1) {$inToPort = "true";}
			if (index($_,"<\/_toPort>")!=-1){
				$inToPort = "false";
			}

			if (index($_,"<_fromPort type=\"r\">")!=-1) {$inFromPort = "true";}
			if (index($_,"<\/_fromPort>")!=-1){
				$inFromPort = "false";
			}
			
			if ($inToPort eq "true") {
				if (index($_,$portID)!=-1) {

					$toPart = $prospectToPart . ":::To";
					$fromPart = $prospectFromPart . ":::From";

					if ($connectionString eq ""){$connectionString = $prospectConnectorName . "ID_SEPERATOR" . $prospectConnectorID . "RM_SEPERATOR" . $prospectConnectorRMID . "CONNECTOR_SEPERATOR" . $toPart . "CONNECTOR_SEPERATOR" . $fromPart;}
					else {$connectionString = $connectionString . "ARRAY_SEPERATOR" . $prospectConnectorName . "ID_SEPERATOR" . $prospectConnectorID . "RM_SEPERATOR" . $prospectConnectorRMID . "CONNECTOR_SEPERATOR" . $toPart . "CONNECTOR_SEPERATOR" . $fromPart;}
				}
			}
			
			if ($inFromPort eq "true") {
				if (index($_,$portID)!=-1) {
					$fromPart = $prospectFromPart . ":::To";
					$toPart = $prospectToPart . ":::From";
					if ($connectionString eq ""){$connectionString = $prospectConnectorName . "ID_SEPERATOR" . $prospectConnectorID . "RM_SEPERATOR" . $prospectConnectorRMID . "CONNECTOR_SEPERATOR" . $toPart . "CONNECTOR_SEPERATOR" . $fromPart;}
					else {$connectionString = $connectionString . "ARRAY_SEPERATOR" . $prospectConnectorName . "ID_SEPERATOR" . $prospectConnectorID . "RM_SEPERATOR" . $prospectConnectorRMID . "CONNECTOR_SEPERATOR" . $toPart . "CONNECTOR_SEPERATOR" . $fromPart;}
				}
			}
		
		}
	
	}
	
	return "$connectionString";
}





