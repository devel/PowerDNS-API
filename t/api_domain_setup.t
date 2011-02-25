use Test::More;
use strict;
use warnings;
use Data::Dump qw(pp);

# the order is important
require PowerDNS::API;
use Dancer::Test;

$Carp::Verbose = 1;

use lib 't';
use TestUtils;

my $domain = test_domain_name;

my $schema = PowerDNS::API::schema();
ok(my $account  = setup_user, 'setup account');

ok(my $r = api_call(PUT => "domain/$domain", { user => $account }), 'setup new domain');
is($r->{r}->{status}, 201, 'ok, created');

ok($r = api_call(GET => "domain/$domain", { user => $account }), "Get domain");
is($r->{records}->[0]->{type}, 'SOA', 'has soa record');


diag pp($r);


done_testing();
