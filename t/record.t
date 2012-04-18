use Test::More;
use strict;
use warnings;
use Data::Dump qw(pp);
use lib 't';

use PowerDNS::API::Schema;

my $schema = PowerDNS::API::Schema->new;

ok(my $domain = $schema->domain->create({ name => "record-test-" . time . ".test",
      type => 'MASTER'
}), "new domain");


ok( my $record = $schema->record->create(
        {   domain_id => $domain->id,
            type      => 'SOA',
            name      => '',
        }
    ), 'soa record');

isa_ok($record, 'PowerDNS::API::Schema::Record::SOA');
my $data = $record->data;

$record->serial(1);
is($record->TO_JSON->{serial}, 1, 'TO_JSON->{serial}');
is($record->TO_JSON->{default_ttl}, 3600, 'TO_JSON->{default_ttl}');

is($record->serial, 1, 'record serial got set');
$data = $record->data;

ok( $record = $schema->record->create(
        {   domain_id => $domain->id,
            name      => 'foobar.' . $domain->name,
            type      => 'A',
            content   => '10.0.0.1'
        }
    ), 'soa record');
isa_ok($record, 'PowerDNS::API::Schema::Record::A');
is($record->TO_JSON->{address}, '10.0.0.1', 'TO_JSON address');
is($record->name, 'foobar.' . $domain->name , 'name is fqdn');
is($record->TO_JSON->{name}, 'foobar', 'TO_JSON name is without the domain');

#diag(Data::Dump::pp($data));

$domain->delete;

done_testing();
