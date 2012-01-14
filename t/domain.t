use Test::More;
use strict;
use warnings;
use Data::Dump qw(pp);
use lib 't';

use PowerDNS::API::Schema;
use Dancer::Test;

use TestUtils;

my $schema = PowerDNS::API::Schema->new;

my $domain_name = test_domain_name;

ok( my $domain = $schema->domain->create(
        {   name => $domain_name,
            type => 'MASTER'
        }), "new domain");


my $soa = $domain->soa;
is( $domain->soa->default_ttl, 3600, "got the default ttl");

ok(my $serial = $domain->increment_serial, 'got serial');
ok(   $serial = $domain->increment_serial, 'got serial');
ok(my $cas = $domain->cas, 'got cas');

ok( $domain = $schema->domain->find( { name => $domain_name }));
is( $domain->soa->serial, $serial, "serial is $serial" );
is( $domain->cas, $cas, "cas is the same");

is( $domain->soa->default_ttl, 3600, "got the default ttl");

done_testing();
