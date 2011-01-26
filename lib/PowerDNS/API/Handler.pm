package PowerDNS::API::Handler;
use Moose;
use URI;
use URI::QueryParam;
use PowerDNS::API::Schema;

extends 'Tatsumaki::Handler';

use namespace::clean;

sub app { shift->application(@_) }

has 'json' => (is => 'rw',
             isa => 'JSON',
             lazy => 1,
             default => sub { JSON->new->convert_blessed->pretty }
);

has schema => (
    isa => 'PowerDNS::API::Schema',
    is  => 'ro',
    lazy_build => 1,
);

sub _build_schema {
    return PowerDNS::API::Schema->new;
}

1;
