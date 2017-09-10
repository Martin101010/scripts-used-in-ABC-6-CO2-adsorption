#!perl

use strict;
use Getopt::Long;
use MaterialsScript qw(:all);

#该脚本判断元素种类，并赋予相应电荷。对于O，判断与之相连的原子是否有Al，并赋予不同的电荷值
my $import_dir="C:/Users/61068/Documents/Materials Studio Projects/trapdoor_Files/Documents/TraPPE/ABC";
opendir (DIR, $import_dir ) || die "Error in opening dir $import_dir\n";
my @list=readdir(DIR);
closedir(DIR);

for (my $l=2; $l<scalar @list; ++$l) {
	my $doc = $Documents{"@list[$l]"};
	@list[$l]=~ /(\S+)\./;
	for (my $i=0; $i<$doc->UnitCell->Atoms->Count; ++$i) {
    		my $atom=$doc->UnitCell->Atoms($i);
   		my $name=$atom->Atom->ElementName;
   		my $connectedAtoms=$atom->AttachedAtoms;
   		my $Al_O=0;
    		if ($name eq "Aluminium") {
    			$atom->Charge=0.48598;}
   		elsif ($name eq "Silicon") {
   			$atom->Charge=0.78598;}
    		elsif ($name eq "Oxygen") {
    			foreach my $atom (@$connectedAtoms) {
    			my $name1=$atom->ElementName;
    			if ($name1 eq "Aluminium") {
    				$Al_O=1;}
			}
    			if ($Al_O==1) {
    				$atom->Charge=-1;}
    			else {
    				$atom->Charge=-0.4;}
    			}
    		 elsif ($name eq "Potassium") {
    			$atom->Charge=0.38340;}
		}
	$doc->save;
	}			