#!/usr/bin/perl
#
# Extract Henry constants from Sorption->Henry Constant results.
#
# How to Use:
# Under Linux shell environment, type the following--
# ./get_SHC_results.pl > results.xls
# 
# Created by Lin
# 09.08/2017
#
use warnings;

my $searchdir="C:/cygwin64/home/61068/sorption";
my $searchstr="---- Henry constant ----";

opendir(DIR,$searchdir) || die "Cann't open $searchdir!";
my @list=readdir(DIR);
closedir(DIR);

for (my $l=2; $l<scalar @list; ++$l) {
	my $file=$list[$l];
	$file=~ s{\..+}{};
	my $dataline=0;
	open(FH, "$searchdir/$list[$l]");
	my @contest=<FH>;
	for (my $i=0; $i<scalar @contest; $i++) {
		my $line=$contest[$i];
		if ($line=~m/$searchstr/) {
			$dataline=$i+5;
			chomp $dataline;
		}
	}
	close(FH);
	my @arr=split' ',$contest[$dataline];
	print "$file \t $arr[5]\n";
}