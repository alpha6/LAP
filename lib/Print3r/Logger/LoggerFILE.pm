package Print3r::Logger::LoggerFILE;

use strict;
use warnings;
use IO::Handle;

use base 'Print3r::Logger::LoggerBase';

sub new {
    my $self = shift->SUPER::new(@_);
    my (%params) = @_;

    $self->{file} = $params{file};
    $self->{'level'} = $params{'level'} || 'error';

    open my $fh, '>>', $params{file} or die $!;
    if (defined $params{'synced'}) {
        $fh->autoflush;
    }

    $self->{fh} = $fh;

    return $self;
}

sub _print {
    my $self = shift;
    my ($message) = @_;

    my $fh = $self->{fh};
    print $fh $message;
}


sub DESTROY {
    close shift->{'fh'};
    return;
}
1;
