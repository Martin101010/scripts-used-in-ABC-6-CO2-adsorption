#!perl
#
# Batch processing for sorption->Henry Constant calculations.
# File import, creating supercell, and charge assign all in one!
#
# Created by Lin
# 09.07/2017
#
use strict;
use Getopt::Long;
use MaterialsScript qw(:all);
use POSIX 'ceil';

# Define input path and read file list from $input_dir.
my $input_dir = "/share/home/apps/export";
opendir (DIR, $input_dir ) || die "Error in opening dir $input_dir\n";
my @list =  readdir(DIR);
closedir(DIR);

# Define adsorbent for Sorption calculation. Adsorbent.xsd file should be ready in advance.
# Don't forget to manually assign charge to adsorbent if you choose "use current" rather than "forcefield assigned".
my $sorptionHenryConstant = Modules->Sorption->HenryConstant;
my $component1 = $Documents{"CO2.xsd"};
$sorptionHenryConstant->AddComponent($component1);

# Main loop
for (my $l = 2; $l < scalar @list;++$l){
	my $doc = Documents->Import("$input_dir/@list[$l]");
	@list[$l] =~ /(\S+)\./;
	my $Cutoffx2 = 24; # Change this if you need a larger cutoff value (plus two).
	my $a = $doc->UnitCell->Lattice3D->LengthA;
	my $b = $doc->UnitCell->Lattice3D->LengthB;
	my $c = $doc->UnitCell->Lattice3D->LengthC;
	my $x = ceil ($Cutoffx2/$a);
	my $y = ceil ($Cutoffx2/$b);
	my $z = ceil ($Cutoffx2/$c);
	$doc->BuildSuperCell($x, $y, $z); # Enlarge unitcell according to vdw cutoff value.
	print "$x x $y x $z cell created for @list[$l].\n";
	$doc->save;
	
	# Loop of charge assign.
	for (my $i=0; $i<$doc->UnitCell->Atoms->Count; ++$i) {
    		my $atom=$doc->UnitCell->Atoms($i);
   		my $name=$atom->Atom->ElementName;
   		my $connectedAtoms=$atom->AttachedAtoms;
   		my $Al_O=0;
    		if ($name eq "Aluminium") {
    			$atom->Charge=0.48598;}
   		elsif ($name eq "Silicon") {
   			$atom->Charge=0.78598;}
    		elsif ($name eq "Oxygen") { # Check if oxygen is connected to aluminium or silicon, and assign corresponding charge.
    			foreach my $atom (@$connectedAtoms) {
    			my $name1=$atom->ElementName;
    			if ($name1 eq "Aluminium") {
    				$Al_O=1;}
			}
    			if ($Al_O==1) {
    				$atom->Charge=-0.41384;}
    			else {
    				$atom->Charge=-0.39299;}
    			}
    		 elsif ($name eq "Sodium") {
    			$atom->Charge=0.38340;}
		}
	
	# Parameters for Sorption->Locate calculations. Note that cutoff values should also be changed here.
	my $results = $sorptionHenryConstant->Run($doc, Settings(
	CurrentForcefield => "/CO2 N2 CH40904", 
	ChargeAssignment => "Use current", 
	"3DPeriodicvdWSummationMethod" => "Atom based", 
	"3DPeriodicElectrostaticSummationMethod" => "Ewald", 
	"3DPeriodicElectrostaticEwaldSumAccuracy" => 0.0001, 
	"3DPeriodicvdWAtomCubicSplineCutOff" => 12, 
	"3DPeriodicvdWChargeGroupCubicSplineCutOff" => 12, 
	NumProductionSteps => 10000000, 
	NumTemperatureSteps => 50, 
	CalculateProbabilityFields => "No", 
	CalculateEnergyFields => "No", 
	CalculateEnergyDistributions => "No", 
	PropertyCalculationInterval => 25));
	
	$doc ->Save;
	$doc ->Discard;
}
