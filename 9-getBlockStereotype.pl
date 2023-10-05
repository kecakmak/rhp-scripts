#!/usr/bin/perl

use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;

my $rhpProject = $ARGV[1];
my $blockName = $ARGV[0];

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


my $parentFolders = qx/find $searchPath \-type f \-exec grep \-H \'<_name type=\"a\">$blockName\' \{\} \\\;/;
my $parentFolder = findCorrectFileName($parentFolders, $blockName);

 if (($parentFolder eq "") or ($parentFolder eq "ERROR")) {
	
	print "ERROR: The Block could not be found. Please enter an existing Block to set the stereotype\n\n\n";
	exit -1; 
 }
 
my $fileContents = getFileContents($parentFolder); 

my $st = getStereotype($fileContents, $blockName); 
print "$st\n";

sub getStereotype {

	my $fileC = $_[0]; 
	my $bl = $_[1]; 
	my $stName = ""; 
	
#find the name of the stereotype in the Block tag: 

#		<IClass type="e">
#			<_id type="a">GUID f5746502-de3f-4901-bfb2-a3a4f63bfb2c</_id>
#			<_myState type="a">8192</_myState>
#			<_rmmServerID type="a">1294532_cImqIgkqEe21o7SZHKptFQ</_rmmServerID>
#			<_name type="a">BL_HBGR_2470</_name>
#			<Stereotypes type="c">
#				<IRPYRawContainer type="e">
#					
#						<IHandle type="e">
#							<_hm2Class type="a">IStereotype</_hm2Class>
#							<_hfilename type="a">$OMROOT\Profiles\SysML\SysMLProfile_rpy\SysML.sbs</_hfilename>
#							<_hsubsystem type="a">SysML::Blocks</_hsubsystem>
#							<_hname type="a">Block</_hname>
#							<_hid type="a">GUID f685432f-691e-4ff1-be70-4d09d19457e1</_hid>
#						</IHandle>
#					
#					
#						<IHandle type="e">
#							<_hm2Class type="a">IStereotype</_hm2Class>
#							<_hfilename type="a">.\MBGrV.sbsx</_hfilename>
#							<_hsubsystem type="a">NVL_Profile::Blocks::MBGrV::_2000::_2400</_hsubsystem>
#							<_hname type="a">2470_E_Motoren_fuer_Schiffsantrieb</_hname>
#							<_hid type="a">GUID 32cd4e70-b8ea-4c76-a80a-7bc008dbc289</_hid>
#							<_hrmmServerID type="a">1293902_cImqIgkqEe21o7SZHKptFQ</_hrmmServerID>
#						</IHandle>
					
#				</IRPYRawContainer>
#			</Stereotypes>

	my $inBlock="false"; 
	my $inCorrectBlock="false"; 
	my $inSt="false"; 
	my $inMBGrV="false"; 
	
	my @fileC_arr = split(/\n/,$fileC) ; 
	
	foreach(@fileC_arr) {
		chomp($_); 
		my $line = $_; 
		if (index($line, "<IClass type=")!=-1) {$inBlock = "true";} 
		
		if (index($line,"<\/IClass>")!=-1) {
			$inBlock = "false"; 
			$inCorrectBlock = "false";
			$inSt = "false"; 
			$inMBGrV = "false"; 
		}
		
		if ($inBlock eq "true") {

			if(index($line, "<_name type=\"a\">$bl</_name>")!=-1){$inCorrectBlock = "true";} 
		}
		
		if ($inCorrectBlock eq "true") {
			if (index($line,"<Stereotypes type")!=-1){$inSt="true";} 
		}
			
		if ($inSt eq "true") {

			if (index($line, "MBGrV.sbsx")!=-1){ 
				$inMBGrV = "true"; 		
			}
		}
		
		if ($inMBGrV eq "true") {

			if (index($line,"<_hname type")!=-1){
				$stName = $line; 

				$stName =~s/<_hname type=\"a\">//ig;
				$stName =~s/<\/_hname>//ig;
				$stName =~s/\s//ig;
				last; 
			}
		
		}
		
		
	}

	return $stName;
}


























