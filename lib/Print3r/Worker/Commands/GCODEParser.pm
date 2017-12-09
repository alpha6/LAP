package Print3r::Worker::Commands::GCODEParser;

use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use feature qw(signatures switch);
no warnings qw(experimental::signatures);
our $VERSION = version->declare('v0.0.1');

sub new {
    my $class = shift;
    bless {}, $class;
}

sub parse_code ( $self, $code ) {
    my $code_data = {};

    for ($code) {
        when (/^M109/) { $code_data = $self->_parse_temp_code($code); }
        when (/^M104/) { $code_data = $self->_parse_temp_code($code); }
        when (/^M190/) { $code_data = $self->_parse_temp_code($code); }
        when (/^M140/) { $code_data = $self->_parse_temp_code($code); }
        when (/^M105/) {
            $code_data = {
                code => $code,
                type => 'info_req',
                };
        }
        when(/^M|G|T/) {
            $code_data = {
                code => $code,
                type => 'common',
                }
        }
        default {
            $code_data = {
                code => $code,
                type => 'unknown',
                }
        }
    }

    return $code_data;
}

sub _parse_temp_code ( $self, $code ) {
    my $data = {
        code => $code,
        type => 'temperature',
    };
    my ( $id, $temp ) = $code =~ /^M(\d{3})\s+S(\d+)/;
    $data->{'target_temp'} = $temp;

    if ( $id == 104 ) {
        $data->{'heater'} = 'hotend';
        $data->{'async'}  = 1;
    }
    elsif ( $id == 109 ) {
        $data->{'heater'} = 'hotend';
        $data->{'async'}  = 0;
    }
    elsif ( $id == 140 ) {
        $data->{'heater'} = 'bed';
        $data->{'async'}  = 1;
    }
    elsif ( $id == 190 ) {
        $data->{'heater'} = 'bed';
        $data->{'async'}  = 0;
    }

    return $data;
}

1;
