

Documents to update: 
1. GUIDS: GUID_REPO.txt 
HOW? 
open the files in the existing model and identify the relevant GUIDs in the file. Then copy and paste into the GUID_Repo.txt 

example: 
template, project, GUID Type, GUID 
block_index_template.xml,SETitanic,BROWSER-ICON,GUID f685432f-691e-4ff1-be70-4d09d19457e1~ALL~BrowserIcon
block_index_template.xml,SETitanic,GROUP-ICON,GUID f685432f-691e-4ff1-be70-4d09d19457e1~ALL~GroupIcon
block_template.xml,SETitanic,_hid,GUID f685432f-691e-4ff1-be70-4d09d19457e1
connection_index_template.xml,SETitanic,BROWSER-ICON,GUID af0f57c0-ca41-456e-87cc-be8bf10a1c55~ALL~BrowserIcon
connection_index_template.xml,SETitanic,GROUP-ICON,GUID af0f57c0-ca41-456e-87cc-be8bf10a1c55~ALL~GroupIcon
connection_template.xml,SETitanic,_hid,GUID f685432f-691e-4ff1-be70-4d09d19457e1
port_template.xml,SETitanic,_hid,GUID b04e5e63-f5d7-4e3d-8000-2e07f5be4e8a
port_index_template.xml,SETitanic,BROWSER-ICON,GUID b04e5e63-f5d7-4e3d-8000-2e07f5be4e8a~ALL~BrowserIcon
port_index_template.xml,SETitanic,GROUP-ICON,GUID b04e5e63-f5d7-4e3d-8000-2e07f5be4e8a~ALL~GroupIcon


2. Update the Libs file 
Libs file:

sub getEnvironments {
	my $request = $_[0];
	
	
	my %envs = ( 
	WORKSPACE => '/home/zkks/RhapsodyWorkspaces',
	SCRIPTS_WS => '/home/zkks/PerlScripts/Rhapsody First Deployment/rhp-scripts-main', 
	WORKSPACE_Projekt_SETitanic => '/home/zkks/RhapsodyWorkspaces/NVL/SETitanic', 
	RHAPSODY_FILE_DIR_Projekt_SETitanic => 'Projekt_SETitanic_rpy/', 
	PROJECTAREA_Projekt_SETitanic => 'iOjfYfj9Eeyg2Yb4jthRGQ', 
	WORKSPACE_ADAS_5 => '/home/zkks/RhapsodyWorkspaces/ADAS',
	RHAPSODY_FILE_DIR_ADAS_5 => 'ADAS_5_rpy/', 
	PROJECTAREA_ADAS_5 => "iOjfYfj9Eeyg2Yb4jthRGQ");
	

	my $env = $envs{$request}; 
	return $env; 
	
	
}
id for the project area can be retrieved from the rhapsody files of the existing Rhapsody project 


3. Update the IDs file (generate IDs via importing) 





# List Blocks 

my $rhpProject = $ARGV[0];

#Linux
my $wsName = "WORKSPACE_" . $rhpProject; 
my $workspace = getEnvironments($wsName); 

my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);




# Link to Requirement
my $block = $ARGV[0];
my $type = $ARGV[1];
my $targetLink = $ARGV[2];
my $rhpProject = $ARGV[3];
#my $targetLink = "https://jazz.net/sandbox01-rm/resources/BI_H6ar9SnLEe2zB-tVgYH0_w";


#Linux
my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);



# Set Stereotype 

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

my $wsPath = getEnvironments("WORKSPACE");

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);


# Create Ports 
my $portBlock = $ARGV[0];
my $newPort = $ARGV[1];
my $portSt = $ARGV[2];
my $rhpProject = $ARGV[3];

my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $wsPath = getEnvironments("WORKSPACE");

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);


# connect ports 

# inputs
my $fromPart = $ARGV[0];
my $fromPort = $ARGV[1];
my $toPart = $ARGV[2];
my $toPort = $ARGV[3]; 
my $rhpProject = $ARGV[4];

# Initialize the global variables. 
#Linux

my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $workspace = getEnvironments($wsName);
my $rhapsody_file_dir = getEnvironments($fileDirName);
my $projectArea = getEnvironments($projAreaName);







