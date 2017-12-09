package Print3r::Logger;

use strict;
use warnings;

use Print3r::Logger::LoggerFILE;
use Print3r::Logger::LoggerSTDERR;

sub get_logger {
    my $class = shift;
    my ( $type, @args ) = @_;

    if ( $type eq 'file' ) {
        return Print3r::Logger::LoggerFILE->new(@args);
    }
    else {
        return Print3r::Logger::LoggerSTDERR->new(@args);
    }

}

1;
