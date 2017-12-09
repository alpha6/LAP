#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use lib 'lib';
use AnyEvent;
use AnyEvent::Handle;

use Getopt::Long;

use Print3r::LAP;
use IO::Pty;
use IO::Termios;

my $cv = AE::cv;

say 'Starting printer emulator...';
my $pty = IO::Pty->new();
$pty->set_raw();


say "pty: ".$pty->ttyname();

my $stty = IO::Termios->new($pty);
$stty->set_mode("115200,8,n,1");
$stty->setflag_echo( 0 );

my $printer = Print3r::LAP->connect($stty);
$cv->recv;
