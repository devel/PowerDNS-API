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
my $slave_domain = "slave-$domain";

my $schema = PowerDNS::API::schema();
ok(my $account  = setup_user, 'setup account');
ok(my $account2 = setup_user, 'setup account 2');

$P::current_user = $account;

my $r;

ok($r = api_call(GET => "domain/", { user => $account->name } ), 'get list of domains');
is($r->{domains} && scalar @{ $r->{domains} }, 0, 'empty list');

ok($r = api_call(PUT => "domain/$slave_domain", { type => 'slave', user => $account } ), 'setup new slave domain, no master');
is($r->{r}->{status}, 400, 'master parameter required');

ok($r = api_call(PUT => "domain/$slave_domain", { type => 'slave', master => '127.0.0.2', user => $account } ),
       'setup new slave domain');
is($r->{r}->{status}, 201, 'ok, created');

ok($r = api_call(PUT => "domain/$domain", { user => $account }), 'setup new domain');
is($r->{r}->{status}, 201, 'ok, created');
# diag pp($r);

ok($r = api_call(GET => "domain/", { user => $account } ), 'get list of domains');
diag pp($r);
is($r->{domains} && scalar @{ $r->{domains} }, 2, 'two domains in the list');

ok($r = api_call(PUT => "domain/$domain"), 'setup the same domain again');
is($r->{r}->{status}, 409, 'domain already exists');
like($r->{error}, qr/domain exists/, 'got error message');

ok($r = api_call(GET => "domain/$domain", { user => $account2 }), "Get domain from account2");
is($r->{r}->{status}, 401, 'unauthorized');
is($r->{error}, 'unauthorized', 'got error');

ok($r = api_call(GET => "domain/$domain"), "Get domain");
ok($r->{domain}, "got domain back");
is($r->{domain}->{name}, $domain, 'got the right domain');
is($r->{domain}->{type}, 'MASTER', 'new domain got setup as master');

ok($r = api_call(POST => "domain/$domain", { type => 'slave', master => '127.0.0.3', user => $account2 }),
      "Change domain to be SLAVE with another account");
is($r->{r}->{status}, 401, 'unauthorized');

ok($r = api_call(POST => "domain/$domain", { type => 'slave', master => '127.0.0.3' }), "Change domain to be SLAVE");
is($r->{domain}->{type}, 'SLAVE', 'now slave');

# TODO: test that domain can't be edited from another account

ok($r = api_call(POST => "domain/$domain", { type => 'master' }), "Change domain back to be master");
is($r->{domain}->{type}, 'MASTER', 'now master');

ok($r = api_call(POST => "record/$domain", { type => 'NS', name => '', content => 'ns1.example.com' }), 'setup NS record');
ok($r->{record}->{id}, 'got an ID');
is($r->{record}->{type}, 'NS', 'is an NS record');

ok($r = api_call(POST => "record/$domain", { type => 'A', name => 'www', content => '10.0.0.1' }), 'setup A record');
ok($r->{record}->{id}, 'got an ID');
is($r->{record}->{content}, '10.0.0.1', 'correct content');

my $id = $r->{record}->{id};

ok($r = api_call(PUT => "record/$domain/$id", { content => '10.0.0.2' }), 'change A record');
is($r->{record}->{content}, '10.0.0.2', 'correct content');


ok( $r = api_call(
        POST => "record/$domain",
        {   type    => 'TXT',
            name    => '_spf',
            content => 'some text goes here',
            ttl     => 600
        }
    ),
    'setup TXT record with TTL'
);
ok($r->{record}->{id}, 'got an ID');
is($r->{record}->{ttl}, 600, 'correct TTL');

ok($r = api_call(GET => "domain/$domain", { type => 'A', name => 'www' }), "Get records with filter");
ok($r->{domain}, "got domain back");
is($r->{domain}->{name}, $domain, 'got the right domain');
is($r->{records}->[0]->{name}, 'www', 'got the right record name');

ok($r = api_call(DELETE => "record/$domain/$id"), 'delete TXT record');

$id = $r->{record}->{id};

ok($r = api_call(PUT => "domain/sub2.$domain", { user => $account2 }), 'setup sub-domain with another account');
is($r->{r}->{status}, 403, 'forbidden');

ok($r = api_call(PUT => "domain/sub.$domain", { user => $account }), 'setup sub-domain with the same account');
is($r->{r}->{status}, 201, 'created');

# diag pp($r);

$account->delete;
$account2->delete;

done_testing();
