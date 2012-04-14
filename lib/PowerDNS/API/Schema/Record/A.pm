package PowerDNS::API::Schema::Record::A;
use Moose;
extends 'PowerDNS::API::Schema::Record';

sub TO_JSON {
    my $self = shift;
    my $data = $self->SUPER::TO_JSON;
    $data->{address} = $self->content;
    return $data;
}

1;
