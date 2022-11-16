
#!/usr/bin/perl

use warnings;
use strict;
use TimeDate;
use MBSEDialogsBackendLibs;

my $rhpProject = $ARGV[0];

#Linux
my $wsName = "WORKSPACE_" . $rhpProject; 
my $fileDirName = "RHAPSODY_FILE_DIR_" . $rhpProject; 
my $projAreaName = "PROJECTAREA_" . $rhpProject; 

my $workspace = $ENV{$wsName};
my $rhapsody_file_dir = $ENV{$fileDirName};
my $projectArea = $ENV{$projAreaName};

my $fullPath = $workspace  . "\/" .  $rhapsody_file_dir;
my $searchPath = $fullPath ;

my $parentFolders = qx/find $fullPath \-type f \-exec grep \-H \'<_hname type=\"a\">Block<\/_hname>\' \{\} \\\;/;

my @file_Arr = split(/\n/,$parentFolders); 

my @blockFiles_arr = "";
my $blockFiles="";
foreach(@file_Arr){
	chomp($_);
	my $line = $_; 
	
	$line=findCorrectFileName($line, "<_hname type=\"a\">Block<\/_hname>");
	
	if(index($blockFiles, $line)!=-1){ 
		next;	
	}
	else {
		if ($blockFiles eq ""){$blockFiles = $line;}
		else{$blockFiles = $blockFiles . "00000" . $line;} 
	
	}
	
	
}

@blockFiles_arr = split("00000", $blockFiles); 

my $fileBlockFinal = ""; 

foreach(@blockFiles_arr) {
	chomp($_);
	my $fileName = $_;
	open(INI, '<', $fileName) or die "cannot open file $_"; 
	my $inClass = "false"; 
	
	my $names = ""; 
	my $nameProspect = ""; 
	
	while(<INI>) {
		chomp($_); 
		my $line = $_;
		if (index($line, "<IClass type=")!=-1) {$inClass = "true";} 
		if (index($line, "<\/IClass>")!=-1) {
			$inClass = "false"; 
			$nameProspect = ""; 
		}
		
		if ($inClass eq "true") {
			if (index($line, "<_name type=")!=-1) {
			$nameProspect = $line;
			$nameProspect =~s/<_name type=\"a\">//ig;
			$nameProspect =~s/<\/_name>//ig;
			$nameProspect =~s/\t//ig; 
			}
		
			if (index($line, "<_hname type=\"a\">Block<\/_hname>")!=-1) {
				if ($names eq "") {$names = $nameProspect;} 
				else {$names=$names . "\n\t" . $nameProspect;}
			}
		
		}
		
	}
	
	my ($file,$ext) = split('\.', $fileName); 
	my @file_arr = split("\/", $file); 	
	my $pureFile = $file_arr[-1];
	if ($fileBlockFinal eq "") { 
		$fileBlockFinal = $pureFile . " : \n\t" . $names;
	}
	else {
		$fileBlockFinal = $fileBlockFinal . "\n\n" . $pureFile . " : \n\t" . $names;
	
	}
	
	
}

print $fileBlockFinal . "\n"; 