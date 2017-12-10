package Print3r::LAP;

use strict;
use warnings;

use feature qw(say signatures);
no warnings qw(experimental::signatures);

our $VERSION = version->declare('v0.0.3');

use Carp;
use AnyEvent::Handle;

use Data::Dumper;

use Print3r::Logger;
use Print3r::Worker::Commands::GCODEParser;
my $parser = Print3r::Worker::Commands::GCODEParser->new;

my $log = Print3r::Logger->get_logger(
    'stderr',
    level  => 'debug'
);

my $temp_change_step = 1;
my $temp_timer;

sub _new {
    bless {}, shift;
}

sub connect ( $class, $stty ) {
    my $self = {
        hotend_temp => 22,
        bed_temp    => 22,
    };

    my $hdl;

    $log->debug('Creating listener...');
    $hdl = AnyEvent::Handle->new(
        fh      => $stty,
        on_read => sub {
            $hdl->push_read(
                line => sub {
                    my ( undef, $line ) = @_;    
                    $line =~ s/\r\n?//g; #I don't know wtf with the line separator, but it doesn't removes \r from line
                
                    $log->debug( sprintf( 'Got line: %s', $line ) );
                    $self->process_line( $hdl, $line );
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


    $self->{'handle'} = $hdl;


    bless $self, $class;

    return $self;
}

sub process_line ( $self, $handle, $line ) {
    $log->debug( sprintf( 'Processing line: %s', $line ) );

    my $code_data = $parser->parse_code($line);

    $log->debug( "Parsed command: " . Dumper($code_data) );

    
    if ( $code_data->{'type'} eq 'common' ) {
        $self->_send_reply( sprintf "ok %s", $code_data->{'code'} );
    }
    elsif ( $code_data->{'type'} eq 'info_req' ) {
        if ( $code_data->{'code'} eq 'M105' ) {    #Return current temp
            $self->_send_reply(
                sprintf "ok T:%s.0 /0.0 \@0 B:%s.0 /0.0 \@0",
                $self->{'hotend_temp'},
                $self->{'bed_temp'}
            );
        }
    }
    elsif ( $code_data->{'type'} eq 'temperature' ) {

        #Process temperature changes
        if ( $code_data->{'async'} == 0 ) {

            my $heater_name = $code_data->{'heater'} . '_temp';
            $temp_timer = AnyEvent->timer(
                after    => 0.5,
                interval => 0.5,
                cb       => sub {
                    if ( $code_data->{'target_temp'} > $self->{$heater_name} ) {
                        $self->{$heater_name} += $temp_change_step;
                        if ( $code_data->{'target_temp'} <
                            $self->{$heater_name} )
                        {
                            $self->{$heater_name} = $code_data->{'target_temp'};
                        }
                    }
                    elsif (
                        $code_data->{'target_temp'} < $self->{$heater_name} )
                    {
                        $self->{$heater_name} -= $temp_change_step;
                        if ( $code_data->{'target_temp'} >
                            $self->{$heater_name} )
                        {
                            $self->{$heater_name} = $code_data->{'target_temp'};
                        }
                    }
                    else {
                        #Temperature reached. Send message and remove timer
                        $self->_send_reply(
                            sprintf "ok T:%s.0 /0.0 \@0 B:%s.0 /0.0 \@0",
                            $self->{'hotend_temp'},
                            $self->{'bed_temp'}
                        );
                        undef $temp_timer;
                        return;
                    }

                    $self->_send_reply(

                        sprintf "T:%s.0 /0.0 \@0 B:%s.0 /0.0 \@0",
                        $self->{'hotend_temp'},
                        $self->{'bed_temp'},
                        int rand(255),
                    );
                }
            );
        }
        else {
            $self->{ $code_data->{'heater'} . '_temp' } =
              $code_data->{'target_temp'};
            $self->_send_reply(

                sprintf(
                    "ok T:%s.0 /0.0 \@0 B:%s.0 /0.0 \@0",
                    $self->{'hotend_temp'},
                    $self->{'bed_temp'}
                )
            );
        }
    } else {
        $log->warn(sprintf("wtf %s", $code_data->{'code'}));
        $self->_send_reply( sprintf "not ok Unknown command: %s",
            $code_data->{'code'} );
    }
}

#make small delay before reply
sub _send_reply ( $self, $reply ) {
    $log->debug("_send_reply called");
    my $timer;
    $timer = AnyEvent->timer(
        after => 0.2,
        cb    => sub {
            $log->debug( sprintf( "reply [%s]", $reply ) );
            $self->{'handle'}->push_write( sprintf( "%s\015\012", $reply ) );
            undef $timer;
        }
    );
}

sub DESTORY {
    my $self = shift;
    delete $self->{'self_closure'};
    undef $self;
}

1;
