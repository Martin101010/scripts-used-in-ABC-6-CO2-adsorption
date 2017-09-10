#!perl

use strict;
use Getopt::Long;
use MaterialsScript qw(:all);

my $import_dir = "D:/xftp download/step2_FD"; 
my $export_dir = "D:/xftp download/step2_FD_s";
        
opendir (DIR, $import_dir ) || die "Error in opening dir $import_dir\n";
my @list = readdir(DIR);
closedir(DIR);

for (my $l = 2; $l < scalar @list;++$l)
	{
	my $doc = Documents->Import("$import_dir/@list[$l]");
	@list[$l] =~ /(\S+)\./;
	$doc->BuildSuperCell(2, 2, 2);
	$doc ->Export("$export_dir/$1_s.cif");
	$doc->discard;
	}