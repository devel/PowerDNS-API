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
            type      => 'SOA'
        }
    ), 'soa record');

isa_ok($record, 'PowerDNS::API::Schema::Record::SOA');
my $data = $record->data;

$record->serial(1);
is($record->serial, 1, 'record serial got set');
$data = $record->data;

#diag(Data::Dump::pp($data));

done_testing();
