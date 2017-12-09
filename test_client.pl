#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use lib 'lib';
use AnyEvent;
use AnyEvent::Handle;

use File::Basename;

use Try::Tiny;

use Getopt::Long;

use IO::Pty;
use IO::Termios;
use Print3r::Logger;
use Print3r::LAP;

my $log = Print3r::Logger->get_logger( 'stderr', level => 'debug' );

my $cv = AE::cv;

say 'Starting test client...';

my $stty = IO::Termios->open('/dev/pts/2');
# my $stty = IO::Termios->open('/dev/ttyUSB0');

$stty->set_mode("115200,8,n,1");
$stty->setflag_echo(0);

my $hdl;
local $/ = "\r\n";

$log->debug('Creating listener...');
$hdl = AnyEvent::Handle->new(
    fh      => $stty,
    on_read => sub {
        $hdl->push_read(
            line => sub {
                my ( undef, $line ) = @_;
                chomp $line;
                $log->debug( sprintf( 'Got line: %s', $line ) );
            }
        );
    },
    on_eof => sub {
        $log->info("client connection: eof");
        exit(0);
    },
    on_error => sub {
        $log->error("Client connection error: $!");
        exit(1);
    },
) || die $!;

my $w = AnyEvent->timer(
    after    => 1,
    interval => 10,
    cb       => sub { $hdl->push_write("M105\015\012"); }
);

$cv->recv;
