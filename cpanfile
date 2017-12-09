requires 'AnyEvent';
requires 'JSON';
requires 'Try::Tiny';
requires 'Getopt::Long';
requires 'Carp';
requires 'IO::Pty';
requires 'IO::Termios';

on test => sub {
    requires 'Test::More';
    requires 'Test::Deep';
    requires 'Test::MonkeyMock';
};