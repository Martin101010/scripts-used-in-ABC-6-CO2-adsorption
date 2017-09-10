#!perl
#
# Buddha with me! Bugs retreat!
#
# Purpose:
# This script subsitutes atom A to atom B in a unitcell randomly. For zeolites, it can also check if lowenstein's rule
# is satisfied. This script can process all the xsd files in the current folder, substitute for "a" times, and export the
# cif file that satisfies the lowenstein's rule to export_dir.
#
# cif verson!
# Import the cif files while processing substitution and exporting.
#
# 
# Modifications:
# 1. Function added: Batch processing all the files in a given folder.
# 2. Function added: Substitution for "a" times (user define).
# 3. Function added: Check if structures satisify lowenstein's rule. When satisfied, export cif files to given folder path.
# 4. Function midified: If a substituted structure doesn't satisfy lowenstein's rule, the script will jump out of the 
#    subroutine rather than kill itself.
#
# Modified by Lin.
# 09.06/2017
#

use strict;
use warnings;
use List::Util qw(shuffle); 	# Allows randomizing of the atoms in an array
use POSIX; 			# Allows use of ceil to round-up numbers
use MaterialsScript qw(:all);

my $inputdir="/share/home/apps/Lin/step2";
my $export_dir = "/share/home/apps/Lin/step3_20%";
opendir (DIR, $inputdir ) || die "Error in opening dir $inputdir\n";
my @list=readdir(DIR);
closedir(DIR);
my $return;

for (my $a=1; $a<=100; ++$a) {
for (my $l=2; $l<scalar @list; ++$l) {
	$list[$l]=~ /(\S+)\./;
# Lowenstein's rule applies to substitution of Aluminium in zeolite and states that no two
# Al atoms can share a common oxygen.
sub CheckLowenstein {
	my ($atom) = @_;
	#Rule states that Al-O-Al linkages are forbidden
	my $attached = $atom->AttachedAtoms;
	foreach my $firstAtom (@$attached) {
		#Only care about oxygens
		if($firstAtom->ElementSymbol eq "O") {
			my $oxyAttached = $firstAtom->AttachedAtoms;
			foreach my $secondAtom (@$oxyAttached) {
				if($secondAtom->ElementSymbol eq "Al") {
					return 0; #Lowenstein broken
				}
			}
		}
	}
	return 1; #Lowenstein satisfied
}
# Main routine to substitute atoms
sub SubstituteAtoms {
	my ($doc, $pcChange, $original, $new, $lowenstein)= @_;
	# Build bonds first! Otherwise "sub CheckLowenstein" won't work!
	my $results = $doc->CalculateBonds(Settings(
	MaxBondLength => 1.200,
	MinBondLength => 0.600));
	# Change the symmetry to P1
	$doc->MakeP1;
	srand;
	# Grab the collection of atoms in the unit cell
	my $atoms = $doc->UnitCell->Atoms;
	# Store the original atoms in an array
	my @originalAtoms;
	foreach my $atom (@$atoms) {
		if($atom->ElementSymbol eq "$original") {push(@originalAtoms, $atom);}
	}
	# Check to see if there are any atoms to modify
	if (scalar @originalAtoms == 0) {die "There are no atoms of element $original to modify\n";}
	# Randomize the atom positions in the array
	my @shuffledOriginalAtoms = shuffle(@originalAtoms);
	# calculate the number of atoms to change. The ceil commanound rounds up. If you wish to
	# round down, use int instead of ceil.
	my $numToChange = ceil (($pcChange/100) * scalar @shuffledOriginalAtoms);
	# Iterate through a counter and search for an atom to change
	for(my $i=0; $i<$numToChange; ++$i) {
		# Check to see if there are any atoms to modify
		if (scalar @shuffledOriginalAtoms == 0) {
		$doc->Discard;
		print "Modified $i atoms. There are no atoms of element $original to modify\n";
		return }
		my $attempts = 0;
		# Look for an atom to modify
		my $atom=undef;
		while(!$atom && scalar @shuffledOriginalAtoms > 0) {
			my $index = int rand( scalar @shuffledOriginalAtoms);
			$atom = $shuffledOriginalAtoms[$index];
			# Check we haven't already changed it and it satisfies Lowenstein rule (optionally)
			if($atom->ElementSymbol eq "$new") {
				splice @shuffledOriginalAtoms, $index, 1; $atom = undef;
			} elsif ($lowenstein eq "Yes") { 
				if (!CheckLowenstein($atom)) {
					splice @shuffledOriginalAtoms, $index, 1; $atom = undef;	
				}	
			}
			++$attempts;
		}
		# Check if atom is still undefined as this means Lowensteins rule has been broken
		if(!$atom) {
			print "Unable to satisfy Lowenstein's rule.\n";
			# Count the number of atoms changed and report this.
			my $modAtoms = 0;
			foreach my $at (@{$doc->UnitCell->Atoms}) {
				if ($at->ElementSymbol eq "$new") { ++$modAtoms;}
			}
			print "$modAtoms atoms have been modified to $new element.\n";
			$return=0;
		} else {
			#Change the element and display style(disabled).
			$atom->ElementSymbol = "$new";
			#$atom->Style = "Ball and Stick";
			$return=1;
		}
	}
if ($return==1) {
print "Lowenstein's rule satisfied. \$return is $return.\n";
$doc ->Export("$export_dir/$1_$a.cif");}
$doc->Discard;
}
# Specify the percentage number of silicons to change.
my $xsd = Documents->Import("$inputdir/$list[$l]");# Please don't change it.
my $percentChange = 20;		# Percentage of atoms of original element to change
my $originalElement = "Si";	# Original element to change to new element
my $newElement = "Al";		# New element
my $obeyLowenstein = "Yes";	# Whether to obey Lowenstein's for zeolites
SubstituteAtoms($xsd, $percentChange,$originalElement, $newElement, $obeyLowenstein);
}
}
