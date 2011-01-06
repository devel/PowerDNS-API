package PowerDNS::API::Config;
use MooseX::Singleton;
extends 'Config::Origami';

has database => (
   isa => 'HashRef',
   is  => 'rw',
);

has secret => (
   isa => 'Str',
   is  => 'rw',
);

sub BUILD {
    my $self = shift;

    die "'secret' configuration is required\n"
      unless $self->secret;
     
    return $self;
}

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    return $class->$orig(config_path => 'config/',
                         @_
                        );
};

1;
