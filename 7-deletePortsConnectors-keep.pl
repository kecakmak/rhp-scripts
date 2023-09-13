

#!/usr/bin/perl

#use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;



# inputs
my $arguments = $ARGV[0];
my ($partToDelete, $portToDelete, $connectorToDelete, $rhpProject) = split("::",$arguments); 
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

if ((($partToDelete ne "") && ($partToDelete ne "NULL"))&& (($portToDelete eq "") || ($portToDelete eq "NULL")) && (($connectorToDelete eq "") || ($connectorToDelete eq "NULL"))) {
	print "all Ports, connectors and the block of this part: $partToDelete will be deleted\n"; 
	my $portsAll = justListPorts($partToDelete,$searchPath);
	print "$portsAll\n";
	
	my ($parentFromBlockandPart, $fromPorts) = split(/==/,$portsAll);
	my ($parentFromBlockPart,$parentFromBlock) = split("-OFPART-",$parentFromBlockandPart);

	my @portNames_arr = split(/::/,$fromPorts);
	for (my $i = 0; $i <= $#portNames_arr; $i++){
	
		my $line = $portNames_arr[$i]; 
		my ($fromPortName, $fromPortID) = split(/\|\|/,$line);
		print "$fromPortName \n $fromPortID\n";
				
		my $portDetails = printPortDetails($fullPath, $fromPortName, $fromPortID, $parentFromBlockPart, $parentFromBlock, $otherPart);
	}
	
	
}

 elsif ((($partToDelete ne "") && ($partToDelete ne "NULL")) && (($portToDelete ne "") && ($portToDelete ne "NULL")) && (($connectorToDelete eq "") || ($connectorToDelete eq "NULL"))) {
	print "all connectors of this port and also the port itself: $portToDelete will be deleted\n"; 
}

 elsif ((($partToDelete ne "") && ($partToDelete ne "NULL")) && (($portToDelete ne "") && ($portToDelete ne "NULL")) && (($connectorToDelete ne "") && ($connectorToDelete ne "NULL"))) {
	print "The connector: $connectorToDelete will be deleted"; 
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





sub printPortDetails{
	my $fullPath = $_[0];
	my $portName = $_[1]; 
	my $portID = $_[2];
	my $parentBlockPartID = $_[3];
	my $parentBlockName = $_[4];
		
	my $blockFiles = qx/ find $fullPath \-type f  \| xargs -n1 awk \'\/<_id type=\"a\">$portID<\\\/_id>\/\,\/<\\\/IPort>\/ \{printf FILENAME \"  \"\; print\}\'  / ;
	$blockFiles=~s/\t/SPACE/ig;
	my @portSpecArr = split(/\n/, $blockFiles); 
	my $portLabel = "";
	my $portMultiplicity="";
	my $portIB = "";
	my $inOtherClass = "false";
	my $inIClassifierHandle = "false";

	foreach (@portSpecArr) {
		chomp($_);
		next if($_ eq "");
		my $line = $_;

		my @lineArr = split("SPACE",$line);
		my $portLine = $lineArr[-1];
		my $elements = @lineArr;
		next if ($elements <2);
		}
	

	my $printConnectors = printPortConnectors($fullPath,$portName,$portID,$parentBlockPartID,$parentBlockName);
	
	my @connector_arr = split("CONN_ARR_SEPERATOR", $printConnectors); 
	my $conn_arr_count = @connector_arr; 
	
	for (my $a=0; $a<$conn_arr_count; $a++){
		my $connector = $connector_arr[$a]; 
		chomp($connector);
		print "\nConnector To Delete: $connector\n";
		
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
	my $fileContents = getFileContents($blockFile);
	
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
			elsif (($partToDelete eq $connectorPartName1) && ($otherPart eq $connectorPartName2)){$connector1 = $connectorPartName1;$connector2 = $connectorPartName2; $connector = $connectorName;}
			elsif (($partToDelete eq $connectorPartName2) && ($otherPart eq $connectorPartName1)){$connector1 = $connectorPartName1;$connector2 = $connectorPartName2; $connector = $connectorName;}
			
			$connectionElement = "$connector\n";
		}

	}
	
	return $connectionElement; 
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
		}
		
		if ($inConnector eq "true"){
		
			if (index($_,"<_name type=\"a\">")!=-1){
				$prospectConnectorName = $_; 
				$prospectConnectorName =~s/<_name type=\"a\">//ig;
				$prospectConnectorName =~s/<\/_name>//ig;
				$prospectConnectorName =~s/\s//ig;
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

					if ($connectionString eq ""){$connectionString = $prospectConnectorName . "CONNECTOR_SEPERATOR" . $toPart . "CONNECTOR_SEPERATOR" . $fromPart;}
					else {$connectionString = $connectionString . "ARRAY_SEPERATOR" . $prospectConnectorName . "CONNECTOR_SEPERATOR" . $toPart . "CONNECTOR_SEPERATOR" . $fromPart;}
				}
			}
			
			if ($inFromPort eq "true") {
				if (index($_,$portID)!=-1) {
					$fromPart = $prospectFromPart . ":::To";
					$toPart = $prospectToPart . ":::From";
					if ($connectionString eq ""){$connectionString = $prospectConnectorName . "CONNECTOR_SEPERATOR" . $toPart . "CONNECTOR_SEPERATOR" . $fromPart;}
					else {$connectionString = $connectionString . "ARRAY_SEPERATOR" . $prospectConnectorName . "CONNECTOR_SEPERATOR" . $toPart . "CONNECTOR_SEPERATOR" . $fromPart;}
				}
			}
		
		}
	
	}
	
	return "$connectionString";
}





