

#!/usr/bin/perl

use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;



# inputs
my $fromPart = $ARGV[0];
my $otherPart = $ARGV[1];
my $rhpProject = $ARGV[2];


# Initialize the global variables. 

my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);

my $fullPath = $workspace  . "\/" .  $rhapsody_file_dir;
my $searchPath = $fullPath ;


	my $fromPortsAll = justListPorts($fromPart);
	my ($parentFromBlockandPart, $fromPorts) = split(/==/,$fromPortsAll);
	my ($parentFromBlockPart,$parentFromBlock) = split("-OFPART-",$parentFromBlockandPart);
	
	
	print "{\n";
	print "\t\"$fromPart\":\n";
	print "\t\t[\n";
	my @portNames_arr = split(/::/,$fromPorts);
	for (my $i = 0; $i <= $#portNames_arr; $i++){
	
		my $line = $portNames_arr[$i]; 
		my ($fromPortName, $fromPortID) = split(/\|\|/,$line);
		print "\t\t\t{\n";
		print "\t\t\t\"$fromPortName\":\n";
		print "\t\t\t\t{\n";
		my $portDetails = printPortDetails($fullPath, $fromPortName, $fromPortID, $parentFromBlockPart, $parentFromBlock, $otherPart);
		print "\t\t\t\t}\n";
		
		if ($i < $#portNames_arr) {print "\t\t\t},\n";}
		else {print "\t\t\t}\n";}

	}


if ($otherPart ne ".") {

	my $toPortsAll = justListPorts($otherPart);
	my ($parentToBlockandPart, $toPorts) = split(/==/,$toPortsAll);
	my ($parentToBlockPart,$parentToBlock) = split("-OFPART-",$parentToBlockandPart);
	print "\t\t],\n";
	print "\t\"$otherPart\":\n";
	print "\t\t[\n";

	my @toPortNames_arr = split(/::/,$toPorts);
	for (my $j = 0; $j <= $#toPortNames_arr; $j++){
		my $line = $toPortNames_arr[$j];
		my ($toPortName,$portID)= split(/\|\|/,$line);
		print "\t\t\t{\n";
		print "\t\t\t\"$toPortName\":\n";
		print "\t\t\t\t{\n";
		my $portDetails = printPortDetails($fullPath, $toPortName, $portID, $parentToBlockPart, $parentToBlock, $otherPart);

		print "\t\t\t\t}\n";
		
		if ($j < $#toPortNames_arr) {print "\t\t\t},\n";}
		else {print "\t\t\t}\n";}
	}
	print "\t\t]\n";


}
else {	print "\t\t]\n";}

print "}\n";

sub justListPorts{
	my $fromPartFileContents = "";
	my $fromPartName = $_[0];
		
	my $fromPartFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$fromPartName\' \{\} \\\;/;
		
	my $fromPartFileName = findCorrectFileName_withType($fromPartFileNames, $fromPartName, "Part"); 

	if ($fromPartFileName eq "ERROR") {
		print "\nERROR(202): Cannot find provided parts: $fromPartName... Check if the part names provided are true\n";
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

	my $fromPartGUID = findGuid($fromPartName, $fromPartFileContents, "IPart");
	my $fromPartRMID = findRmid($fromPartName, $fromPartFileContents, "IPart");

	if (($fromPartGUID eq "ERROR") or ($fromPartRMID eq "ERROR")) {
		print "\nERROR(202): Cannot find provided part $fromPartName... Check if the part names provided are true1\n";
		exit -1;
	}
	
	
	my $fromBlockName = getBlockName($fromPartName, $fromPartFileContents, "IPart"); 

	my $parentFromBlock = findParentName($fromPartGUID, $fromPartFileContents, "IClass");
	
	if ($parentFromBlock eq "ERROR") {
		print "\nERROR(202): Cannot find a parent Block for the provided part $fromPartName... Check if the part names provided are true2\n";
		exit -1;
	}
	
	my $fromBlockFileNames = qx/find $searchPath \-type f \-exec grep \-H \'$fromBlockName\' \{\} \\\;/;
	my $fromBlockFileName = findCorrectFileName_withType($fromBlockFileNames, $fromBlockName, "Class");
	
	
	if ($fromBlockFileName eq "ERROR") {
		print "\nERROR(202): Cannot find main blocks for the provided ports ... Check if the port names provided are true\n";
		exit -1;
	}	
	my $fromBlockFileContents = "";
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
		if ($name ne "") {
			if ($portList eq "") {$portList = $name . "||" . $id;} 
			else {$portList = $portList . "::" . $name . "||" . $id;} 
		}
	}
	
	$portList = $fromPartGUID . "-OFPART-" . $parentFromBlock . "==" . $portList;
	return $portList;
	

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
		
#Find Label 
		if (index($portLine, "<_displayName") !=-1) {#we have Label 
			$portLine =~ s/<_displayName type=\"a\">//ig;
			$portLine =~ s/<\/_displayName>//ig;
			$portLabel = $portLine;
		}

#Find Multiplicity
		if (index($portLine, "<_multiplicity") !=-1) {#we have Multiplicity 
			$portLine =~ s/<_multiplicity type=\"a\">//ig;
			$portLine =~ s/<\/_multiplicity>//ig;
			$portMultiplicity = $portLine;
		}

#Find Interface Block -Start- 
		if (index($portLine, "<_otherClass type=\"r\">")!=-1) { #we are in OtherClass which encapsulates the Interface Block 
			$inOtherClass = "true"; 
		}
		if (index($portLine, "<\/_otherClass>")!=-1) { #exited OtherClass
			$inOtherClass = "false";
			$inIClassifierHandle = "false"; 
		}
		
		if (($inOtherClass eq "true") && (index($portLine, "<IClassifierHandle type=\"e\">")!=-1)) { # we are in IClassifierHandle tag which encapsulates the Interface Block
			$inIClassifierHandle = "true";
		}
		
		if (index($portLine, "<\/IClassifierHandle")!=-1) { # exited IClassifierHandle 
			$inIClassifierHandle = "false"; 
		}
		
		if ($inIClassifierHandle eq "true") { #we are in the encapsulation 
			if (index($portLine, "<_hname")!=-1) { 
				$portLine =~s/<_hname type=\"a\">//ig;
				$portLine =~s/<\/_hname>//ig;
				$portIB = $portLine;
			}
		
		}
#Find Interface Block -End- 
	}
	
	print "\t\t\t\t\"Label\":\"$portLabel\",\n";
	print "\t\t\t\t\"Interface Block\":\"$portIB\",\n";
	print "\t\t\t\t\"multiplicity\":\"$portMultiplicity\",\n";
	print "\t\t\t\t\"connectors\":\n";
	print "\t\t\t\t\t[\n";

	my $printConnectors = printPortConnectors($fullPath,$portName,$portID,$parentBlockPartID,$parentBlockName);
	
	my @connector_arr = split("CONN_ARR_SEPERATOR", $printConnectors); 
	my $conn_arr_count = @connector_arr; 
	
	for (my $a=0; $a<$conn_arr_count; $a++){
		my $connector = $connector_arr[$a]; 
		chomp($connector);
		print "$connector\n";
		
		if ($a < $conn_arr_count-1) {print "\t\t\t\t\t\t},\n";}
		else {print "\t\t\t\t\t\t}\n";}
	
	}
	
	print "\t\t\t\t\t]\n";
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


sub getConnectorFiles{ 
	my $fullPath = $_[0];
	my $portID = $_[1];
	my $connectionString = ""; 
	
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
			my ($connectorName1,$connectorDir1)=split(":::",$connectorPart1);	
			my ($connectorPartName1,$connectorPortName1) = split("<<VIA>>", $connectorName1);
			my ($connectorName2,$connectorDir2)=split(":::",$connectorPart2);
			my ($connectorPartName2, $connectorPortName2) = split("<<VIA>>", $connectorName2);
			$connectorPortName1 = findNameByGUID_UnknownFile($connectorPortName1, $searchPath, "IPort");
			$connectorPortName2 = findNameByGUID_UnknownFile($connectorPortName2, $searchPath, "IPort");
			if ($otherPart eq "."){
				$connector1 = $connectorPortName1;
				$connector2 = $connectorPortName2; 
				$connector = $connectorName; 	
			}
			elsif (($fromPart eq $connectorPartName1) && ($otherPart eq $connectorPartName2)){$connector1 = $connectorPortName1;$connector2 = $connectorPortName2; $connector = $connectorName;}
			elsif (($fromPart eq $connectorPartName2) && ($otherPart eq $connectorPartName1)){$connector1 = $connectorPortName1;$connector2 = $connectorPortName2; $connector = $connectorName;}
			
			my $connectionElement = "\t\t\t\t\t\t{\n" . "\t\t\t\t\t\t\"$connectorDir1\":\"$connector1\",\n" . "\t\t\t\t\t\t\"$connectorDir2\":\"$connector2\",\n" . "\t\t\t\t\t\t\"name\":\"$connector\"\n";

			if ($connectionString eq ""){$connectionString = $connectionElement;}
			else {$connectionString = $connectionString . "CONN_ARR_SEPERATOR" . $connectionElement;}
		}

	}
	
	return $connectionString; 
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
	my $prospectToPort = "";
	my $prospectFromPort = ""; 
	my $prospectConnectorName = ""; 
	my $connectionString = ""; 
	my $fromPart = "";
	my $toPart = ""; 
	my $toPort = ""; 
	my $fromPort = ""; 
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
			$toPort = ""; 
			$fromPort = ""; 
			$prospectToPort = ""; 
			$prospectFromPort = ""; 
			$prospectConnectorName = ""; 
		}
		
#		<IObjectLink type="e">
#			<_id type="a">GUID f6b3ec1b-6b38-48bf-8864-705eeaeeca8d</_id>
#			<_myState type="a">10240</_myState>
#			<_rmmServerID type="a">1294161_cImqIgkqEe21o7SZHKptFQ</_rmmServerID>
#			<_name type="a">PT_HBGR_2220_PT_HBGR_2110</_name>
#			<_toLink type="r">
#				<IHandle type="e">
#					<_hm2Class type="a">IPart</_hm2Class>
#					<_hfilename type="a">.\ST_2100.sbsx</_hfilename>
#					<_hsubsystem type="a">Projekt_SETitanic::System_SETitanic::System_XYZ_Struktur::ST_Systems::ST_2000::ST_2100</_hsubsystem>
#					<_hclass type="a">BL_BA_2100</_hclass>
#					<_hname type="a">PT_HBGR_2110</_hname>
#					<_hid type="a">GUID 2e47c634-0654-4d77-be47-abcf595d73b1</_hid>
#					<_hrmmServerID type="a">1294536_cImqIgkqEe21o7SZHKptFQ</_hrmmServerID>
#				</IHandle>
#			</_toLink>
#			<_fromLink type="r">
#				<IHandle type="e">
#					<_hm2Class type="a">IPart</_hm2Class>
#					<_hid type="a">GUID 96b75b87-49dd-4c36-9995-c54d615c76ac</_hid>
#					<_hrmmServerID type="a">1294172_cImqIgkqEe21o7SZHKptFQ</_hrmmServerID>
#				</IHandle>
#			</_fromLink>
#			<_toPort type="r">
#				<IHandle type="e">
#					<_hm2Class type="a">IPort</_hm2Class>
#					<_hfilename type="a">.\ST_2110.sbsx</_hfilename>
#					<_hsubsystem type="a">Projekt_SETitanic::System_SETitanic::System_XYZ_Struktur::ST_Systems::ST_2000::ST_2100::ST_2110</_hsubsystem>
#					<_hclass type="a">BL_HBGR_2110</_hclass>
#					<_hname type="a">PP_2220</_hname>
#					<_hid type="a">GUID a90cc394-7faa-41ec-9336-fa8b4a258a80</_hid>
#					<_hrmmServerID type="a">1294366_cImqIgkqEe21o7SZHKptFQ</_hrmmServerID>
#				</IHandle>
#			</_toPort>
#			<_fromPort type="r">
#				<IHandle type="e">
#					<_hm2Class type="a">IPort</_hm2Class>
#					<_hfilename type="a">.\ST_2220.sbsx</_hfilename>
#					<_hsubsystem type="a">Projekt_SETitanic::System_SETitanic::System_XYZ_Struktur::ST_Systems::ST_2000::ST_2200::ST_2220</_hsubsystem>
#					<_hclass type="a">BL_HBGR_2220</_hclass>
#					<_hname type="a">PP_2110</_hname>
#					<_hid type="a">GUID c29b6af9-63bc-4842-a7b1-112d33c256aa</_hid>
#					<_hrmmServerID type="a">1294153_cImqIgkqEe21o7SZHKptFQ</_hrmmServerID>
#				</IHandle>
#			</_fromPort>
#		</IObjectLink>
		
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
				$toPort = ""; 
			}

			if (index($_,"<_fromPort type=\"r\">")!=-1) {$inFromPort = "true";}
			if (index($_,"<\/_fromPort>")!=-1){
				$inFromPort = "false";
				$fromPort = "";
				$prospectFromPort = "";
			}
			
			if ($inToPort eq "true") {
				if (index($_,"<_hid type=\"a\">")!=-1){
					if (index($_,$portID)!=-1) {

						$toPart = $prospectToPart;
						$fromPart = $prospectFromPart;

						$toPort = $portID . ":::To";
						$fromPort = "<FROM_PORT_PLACEHOLDER>" . ":::From";
						
						$toPort = $toPart . "<<VIA>>" . $toPort; 
						$fromPort = $fromPart . "<<VIA>>" . $fromPort; 

						if ($connectionString eq ""){$connectionString = $prospectConnectorName . "CONNECTOR_SEPERATOR" . $toPort . "CONNECTOR_SEPERATOR" . $fromPort;}
						else {$connectionString = $connectionString . "ARRAY_SEPERATOR" . $prospectConnectorName . "CONNECTOR_SEPERATOR" . $toPort . "CONNECTOR_SEPERATOR" . $fromPort;}
					}
					else {

						$_ =~s/<_hid type=\"a\">//ig;
						$_ =~s/<\/_hid>//ig;
						$_ =~s/\s//ig;
						$_ =~s/GUID/GUID /ig;
						$prospectToPort = $_;
					}
				}
			}
			
			if ($inFromPort eq "true") {
				if (index($_,"<_hid type=\"a\">")!=-1){
					if (index($_,$portID)!=-1) {

						
						$fromPart = $prospectFromPart;
						$toPart = $prospectToPart;

						$fromPort = $portID . ":::From";
						$toPort = $prospectToPort . ":::To"; 
						
						$toPort = $toPart . "<<VIA>>" . $toPort; 
						$fromPort = $fromPart . "<<VIA>>" . $fromPort; 

						if ($connectionString eq ""){$connectionString = $prospectConnectorName . "CONNECTOR_SEPERATOR" . $toPort . "CONNECTOR_SEPERATOR" . $fromPort;}
						else {$connectionString = $connectionString . "ARRAY_SEPERATOR" . $prospectConnectorName . "CONNECTOR_SEPERATOR" . $toPort . "CONNECTOR_SEPERATOR" . $fromPort;}
					}
					else {
						$_ =~s/<_hid type=\"a\">//ig;
						$_ =~s/<\/_hid>//ig;
						$_ =~s/\s//ig;
						$_ =~s/GUID/GUID /ig;
						$prospectFromPort = $_;
						$connectionString =~s/<FROM_PORT_PLACEHOLDER>/$prospectFromPort/ig;
					
					}
				}
			}
		
		}
	
	}
	return "$connectionString";
}