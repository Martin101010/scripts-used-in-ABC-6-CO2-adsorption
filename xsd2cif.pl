#!perl

use strict;
use Getopt::Long;
use MaterialsScript qw(:all);

my $import_dirname = "E:/xsd"; 
my $export_dirname = "E:/cif";
        
opendir (DIR, $import_dirname ) || die "Error in opening dir $import_dirname\n";
my @list = readdir(DIR);
closedir(DIR);


for (my $l = 2; $l < scalar @list;++$l)
	{
	my $doc = Documents->Import("$import_dirname/@list[$l]");
	@list[$l] =~ /(\S+)\./;
	$doc ->Export("$export_dirname/$1.cif");
	$doc->discard;
	}