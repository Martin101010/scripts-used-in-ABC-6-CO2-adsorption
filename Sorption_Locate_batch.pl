#!perl
#
# Batch processing for sorption->Locate calculations.
# Creat supercell, charge assign, and file import & export all in one!
#
# Created by Lin
# 09.07/2017
#
use strict;
use Getopt::Long;
use MaterialsScript qw(:all);
use POSIX 'ceil';

# Define input and export folder path and read file list from $input_dir.
my $input_dir = "C:/Users/61068/Desktop/test_cif";
my $export_dir = "C:/Users/61068/Desktop/test_L";
opendir (DIR, $input_dir ) || die "Error in opening dir $input_dir\n";
my @list =  readdir(DIR);
closedir(DIR);

# Define adsorbent for Sorption calculation. Adsorbent xsd file should be ready in advance.
# Don't forget to manually assign charge if you choose "use current" rather than "forcefield assign".
my $sorptionLocate = Modules->Sorption->Locate;
my $component1 = $Documents{"Na.xsd"};
$sorptionLocate->AddComponent($component1);

# Main loop
for (my $l = 2; $l < scalar @list;++$l){
	my $doc = Documents->Import("$input_dir/@list[$l]");
	@list[$l] =~ /(\S+)\./;
	my $AlNumb = 0;
	my $DoubleCutoff = 24; # Change this if you need a larger cutoff value (plus two).
	my $a = $doc->UnitCell->Lattice3D->LengthA;
	my $b = $doc->UnitCell->Lattice3D->LengthB;
	my $c = $doc->UnitCell->Lattice3D->LengthC;
	my $x = ceil ($DoubleCutoff/$a);
	my $y = ceil ($DoubleCutoff/$b);
	my $z = ceil ($DoubleCutoff/$c);
	$doc->BuildSuperCell($x, $y, $z); # Enlarge unitcell according to vdw cutoff value.
	print "$x x $y x $z cell created for @list[$l].\n";
	$doc->save;
	
	# Loop of charge assign.
	for (my $i=0; $i<$doc->UnitCell->Atoms->Count; ++$i) {
		my $atom = $doc->UnitCell->Atoms($i);
   		my $name = $atom->Atom->ElementName;
   		   if ($name eq "Aluminium") {
    			$atom->Charge=1.4;
    			$AlNumb+=1;} # Calculate number of cation for charge balance.
   		elsif ($name eq "Silicon") {
   			$atom->Charge=2.4;}
    		elsif ($name eq "Oxygen") {
    			$atom->Charge=-1.2;}
	}
	
	# Parameters for Sorption->Locate calculations. Note that cutoff values should also be changed here.
	$sorptionLocate->Loading($component1) = $AlNumb;
	print "$AlNumb Na ions for @list[$l].\n";
	my $results = $sorptionLocate->Run($doc, Settings(
	CurrentForcefield => "cvff", 
	ChargeAssignment => "Use current", 
	"3DPeriodicElectrostaticSummationMethod" => "Ewald", 
	"3DPeriodicElectrostaticEwaldSumAccuracy" => 0.0001, 
	"3DPeriodicvdWAtomCubicSplineCutOff" => 12, 
	"3DPeriodicvdWChargeGroupCubicSplineCutOff" => 12));
	my $outLowestEnergyStructure = $results->LowestEnergyStructure;
	
	# Export structure as cif format when calculation is done.
	$doc ->Export("$export_dir/$1.cif");
	$doc ->Save;
	$doc ->Discard;
}
