package Print3r::Worker::Commands::PrinterReplyParser;

use v5.20;
use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use feature qw(signatures);
no warnings qw(experimental::signatures);
our $VERSION = version->declare('v0.0.1');

sub new {
	my $class = shift;
	bless {}, $class;
}

sub parse_line ($self, $line) {
    my $type = {};

    for ($line) {
        when (/^ok T:(\d+\.\d+) \/\d+\.\d+/) {
            $type = $self->_parse_temp_line($line);
        }
        when (/^(ok|start)/) {
            $type->{'type'}          = 'ready';
            $type->{'printer_ready'} = 1;
            $type->{'line'}          = $line;
        }
        when (/halt|kill|stop/i) {
            $type->{'type'}          = 'error';
            $type->{'printer_ready'} = 0;
            $type->{'line'}          = $line;
        }
        when (/reset or M999 required/) {
            $type->{'type'}          = 'error';
            $type->{'printer_ready'} = 0;
            $type->{'line'}          = $line;
        }
        when ('Watchdog Reset') {
            $type->{'type'}          = 'error';
            $type->{'printer_ready'} = 0;
            $type->{'line'}          = $line;
        }
        default {
            $type->{'type'}          = 'other';
            $type->{'printer_ready'} = 0;
            $type->{'line'}          = $line;
        }
    }
    return $type;
}

sub _parse_temp_line($self, $line) {
    my $parsed = {};

    $parsed->{'type'} = 'temperature';
    $parsed->{'line'} = $line;
    $parsed->{'B'} = undef;    #Undefined if printer doesn't have heated bed

    my @line = split /\s+/, $line;

    for my $item (@line) {
        if ( $item eq 'ok' ) {
            $parsed->{'printer_ready'} = 1;
        }
        elsif ( $item =~ /T(?<ex_num>\d+)?:(?<temp>\d+\.\d+)/ ) {
            $parsed->{ sprintf( 'E%s', $+{ex_num} || 0 ) } = $+{'temp'};
        }
        elsif ( $item =~ /B:?(\d+\.\d+)/ ) {

            #B\d+\.\d+ - Marlin dialect
            #B:\d+\.\d+ - Smoothieware
            $parsed->{'B'} = $1;
        }
    }

    return $parsed;
}

1;

# RECV: start
# RECV: echo: External Reset
# RECV: Marlin 1.1.0-RC8
# RECV: echo: Last Updated: 2016-12-06 12:00 | Author: (none, default config)
# RECV: Compiled: Apr 13 2017
# RECV: echo: Free Memory: 13426  PlannerBufferBytes: 1232
# RECV: echo:Hardcoded Default Settings Loaded
# RECV: echo:Steps per unit:
# RECV: echo:  M92 X94.00 Y94.00 Z94.00 E540.00
# RECV: echo:Maximum feedrates (mm/s):
# RECV: echo:  M203 X200.00 Y200.00 Z200.00 E25.00
# RECV: echo:Maximum Acceleration (mm/s2):
# RECV: echo:  M201 X3000 Y3000 Z3000 E10000
# RECV: echo:Accelerations: P=printing, R=retract and T=travel
# SENT: M105
# RECV: echo:  M204 P1000.00 R3000.00 T1500.00
# RECV: echo:Advanced variables: S=Min feedrate (mm/s), T=Min travel feedrate (mm/s), B=minimum segment time (ms), X=maximum XY jerk (mm/s),  Z=maximum Z jerk (mm/s),  E=maximum E jerk (mm/s)
# RECV: echo:  M205 S0.00 T0.00 B20000 X20.00 Y20.00 Z20.00 E5.00
# RECV: echo:Home offset (mm)
# RECV: echo:  M206 X0.00 Y0.00 Z0.00
# RECV: Auto Bed Leveling:
# RECV: echo:  M420 S0
# RECV: echo:Endstop adjustment (mm):
# RECV: echo:  M666 X0.00 Y0.00 Z0.00
# RECV: echo:Delta settings: L=diagonal_rod, R=radius, S=segments_per_second, ABC=diagonal_rod_trim_tower_[123]
# RECV: echo:  M665 L185.50 R85.19 S200.00 A0.00 B0.00 C0.00
# RECV: echo:PID settings:
# RECV: echo:  M301 P22.20 I1.08 D114.00
# RECV: echo:Filament settings: Disabled
# RECV: echo:  M200 D1.75
# RECV: echo:  M200 D0
# RECV: echo:Z-Probe Offset (mm):
# RECV: echo:  M851 Z0.00
# RECV: ok T:0.0 /0.0 @:0