package Print3r::Logger::LoggerSTDERR;
use strict;
use warnings;

use base 'Print3r::Logger::LoggerBase';

sub _print {
    my $self = shift;
    my ($message) = @_;

    print STDERR $message;
}

1;
