package PowerDNS::API::Handler::Main;
use strict;
use base qw(PowerDNS::API::Handler);
use namespace::clean;

sub get {
    my $self = shift;
    $self->render('index.html');
    $self->finish;
}

1;
