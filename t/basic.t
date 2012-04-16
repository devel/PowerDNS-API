use Test::More;
use strict;
use warnings;
use Data::Dump qw(pp);

use Test::Mojo;
my $t = Test::Mojo->new('PowerDNS::API');

$Carp::Verbose = 1;

use lib 't';
use TestUtils;

$TestUtils::t = $t;

my $domain = test_domain_name;
my $slave_domain = "slave-$domain";

my $schema = $t->app->schema();
ok(my $account  = setup_user, 'setup account');
ok(my $account2 = setup_user, 'setup account 2');

$TestUtils::current_user = $account;

my $r;

ok($r = api_call(GET => "domain/", { user => $account } ), 'get list of domains');
is($r->{domains} && scalar @{ $r->{domains} }, 0, 'empty list');

ok($r = api_call(PUT => "domain/$slave_domain", { type => 'slave', user => $account } ), 'setup new slave domain, no master arg');
$t->status_is(400, 'master parameter required');

ok($r = api_call(PUT => "domain/$slave_domain", { type => 'slave', master => '127.0.0.2', user => $account } ),
       'setup new slave domain');
$t->status_is(201, 'ok, created');

ok($r = api_call(PUT => "domain/$domain", { user => $account }), 'setup new domain');
$t->status_is(201, 'ok, created');

ok($r = api_call(GET => "domain/", { user => $account } ), 'get list of domains');
is($r->{domains} && scalar @{ $r->{domains} }, 2, 'two domains in the list');

ok($r = api_call(PUT => "domain/$domain"), 'setup the same domain again');
$t->status_is(409, 'domain already exists');
like($r->{error}, qr/domain exists/, 'got error message');

ok($r = api_call(GET => "domain/$domain", { user => $account2 }), "Get domain from account2");
$t->status_is(401, 'unauthorized');
is($r->{error}, 'unauthorized', 'got error');

ok($r = api_call(GET => "domain/$domain"), "Get domain");
ok($r->{domain}, "got domain back");
is($r->{domain}->{name}, $domain, 'got the right domain');
is($r->{domain}->{type}, 'MASTER', 'new domain got setup as master');

ok($r = api_call(POST => "domain/$domain", { type => 'slave', master => '127.0.0.3', user => $account2 }),
      "Change domain to be SLAVE with another account");
$t->status_is(401, 'unauthorized');

ok($r = api_call(POST => "domain/$domain", { type => 'slave', master => '127.0.0.3' }), "Change domain to be SLAVE");
is($r->{domain}->{type}, 'SLAVE', 'now slave');

# TODO: test that domain can't be edited from another account

ok($r = api_call(POST => "domain/$domain", { type => 'master' }), "Change domain back to be master");
is($r->{domain}->{type}, 'MASTER', 'now master');


# diag pp($r);

$account->delete;
$account2->delete;

done_testing();
