#!/usr/bin/perl

# Add the genesis tree to the module search path.
use lib ("$ENV{'GENESIS_EDIR'}/all/perl");

use strict;
use Tk;
use Genesis;

#my $host = shift;
my $f = new Genesis();

my $job_name  = shift;  #$ENV{JOB};
my $step_name = shift;  #$ENV{STEP};

checkJobStep();

my @layers;
my @layerTypes;
my @layerContext;
getLayers($f);
my @copper    = getCopperLayers();
my @drills    = getDrillLayers();
my $mainDrill = getMainDrill();
checkCopperExist();

$f->COM(
	"affected_layer",
	mode     => "all",
	affected => "no"
);

$f->COM( "affected_filter",
	filter =>
	  "(type=solder_mask|silk_screen|solder_paste&context=board&side=top)" );
$f->COM(
	"register_layers",
	reference_layer => "$copper[0]",
	tolerance       => "1.5",
	zero_lines      => "no",
	reg_mode        => "affected_layers"
);

if ($mainDrill) {
	$f->COM(
		"affected_layer",
		name     => "$mainDrill",
		mode     => "single",
		affected => "yes"
	);
	$f->COM(
		"register_layers",
		reference_layer => "$copper[0]",
		tolerance       => "1.5",
		zero_lines      => "no",
		reg_mode        => "affected_layers"
	);

	$f->COM( "affected_filter",
		filter =>
		  "(type=signal|power_ground|mixed&context=board&side=bottom|inner)" );
	$f->COM(
		"register_layers",
		reference_layer => "$mainDrill",
		tolerance       => "1.5",
		zero_lines      => "no",
		reg_mode        => "affected_layers"
	);
}
else {
	$f->COM( "affected_filter",
		filter =>
		  "(type=signal|power_ground|mixed&context=board&side=bottom|inner)" );
	$f->COM(
		"register_layers",
		reference_layer => "$copper[0]",
		tolerance       => "1.5",
		zero_lines      => "no",
		reg_mode        => "affected_layers"
	);
}
$f->COM( "affected_filter",
	filter =>
	  "(type=solder_mask|silk_screen|solder_paste&context=board&side=bottom)" );
$f->COM(
	"register_layers",
	reference_layer => "$copper[$#copper]",
	tolerance       => "1.5",
	zero_lines      => "no",
	reg_mode        => "affected_layers"
);

if ( $#drills > 0 ) {
	foreach (@drills) {
		allignBV($_) if (/bv\d+-\d+$/);
	}
}
$f->COM("clear_layers");
$f->COM(
	"multi_layer_disp",
	mode       => "many",
	show_board => "yes"
);
$f->COM("zoom_home");

$f->COM(
	"affected_layer",
	mode     => "all",
	affected => "no"
);

sub allignBV {
	my $bv = shift;
	my ( $t, $b ) = $bv =~ /bv(\d+)-(\d+)$/;
	if ( $t == 1 ) {
		$f->COM(
			"register_layers",
			reference_layer => "$copper[$#copper]",
			tolerance       => "1.5",
			zero_lines      => "no",
			reg_mode        => "layer_name",
			register_layer  => "$bv"
		);

	}
	else {
		$f->COM(
			"register_layers",
			reference_layer => "$copper[$b-1]",
			tolerance       => "1.5",
			zero_lines      => "no",
			reg_mode        => "layer_name",
			register_layer  => "$bv"
		);
	}
}

sub getLayers {
	my $f = shift;
	$f->INFO(
		entity_type => "matrix",
		entity_path => "$job_name/matrix",
		data_type   => "ROW"
	);

	my $a = $f->{doinfo}{gROWname}[0];
	my $b = $f->{doinfo}{gROWlayer_type}[0];
	my $c = $f->{doinfo}{gROWcontext}[0];
	my $i = 0;

	while ($a) {
		$layers[$i]       = $a;
		$layerTypes[$i]   = $b;
		$layerContext[$i] = $c;
		$i++;
		$a = $f->{doinfo}{gROWname}[$i];
		$b = $f->{doinfo}{gROWlayer_type}[$i];
		$c = $f->{doinfo}{gROWcontext}[$i];
	}
}

sub getMainDrill {
	my $drill = "";
	foreach my $x (@drills) {
		($_) = $x =~ m/^.+\.(.+?)$/;
		$drill = $x if (/^dri$/);
	}
	return $drill;
}

sub getDrillLayers {
	my @drill;
	my $i = 0;
	foreach (@layerTypes) {
		push( @drill, $layers[$i] )
		  if (/drill/);
		$i++;
	}
	return @drill;
}

sub getCopperLayers {
	my @copper;
	my $i = 0;
	foreach (@layerTypes) {
		push( @copper, $layers[$i] )
		  if ( /signal/ || /power_ground/ || /mixed/ )
		  && ( $layerContext[$i] =~ /board/ );
		$i++;
	}
	return @copper;
}

sub getIndex {
	my $aa    = shift;
	my @a     = @$aa;
	my $match = shift;
	return -1 if not @a;

	my $i     = 0;
	my $index = -1;
	my $x;
	foreach $x (@a) {
		$index = $i if $x eq $match;
		$i++;
	}
	return $index;
}

sub checkJobStep {

	unless ($job_name) {
		my $mw = MainWindow->new( -title => '' );
		$mw->withdraw();
		$mw->messageBox(
			-icon    => 'error',
			-message => 'Please run this script from within a Job !',
			-title   => 'Error',
			-type    => 'Ok'
		);
		exit(1);
	}

	unless ($step_name) {
		my $mw = MainWindow->new( -title => '' );
		$mw->withdraw();
		$mw->messageBox(
			-icon    => 'error',
			-message => 'Please run this script from within a Step !',
			-title   => 'Error',
			-type    => 'Ok'
		);
		exit(1);
	}

}

sub checkCopperExist {
	unless (@copper) {
		my $mw = MainWindow->new( -title => '' );
		$mw->withdraw();
		$mw->messageBox(
			-icon    => 'error',
			-message => 'No Copper Layers to register !',
			-title   => 'Error',
			-type    => 'Ok'
		);
		exit(1);
	}

}
