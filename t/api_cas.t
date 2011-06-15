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

$P::current_user = $account;


ok(my $r = api_call(PUT => "domain/$domain", { user => $account }), 'setup new domain');
is($r->{r}->{status}, 201, 'ok, created');
ok(my $cas = $r->{domain}->{cas}, 'got cas value');

ok($r = api_call(GET => "domain/$domain"), "Get domain");
ok($r->{domain}, "got domain back");
is($r->{domain}->{name}, $domain, 'got the right domain');
is($r->{domain}->{cas}, $cas, "got the same cas value ($cas)");

ok( $r = api_call(POST => "domain/$domain",
    {type => 'slave', master => '127.0.0.3', cas => 'wrong'}),

    "Change domain to be SLAVE, wrong cas value"
);
is($r->{r}->{status}, 409, 'conflict, wrong cas');

ok($r = api_call(POST => "domain/$domain", { type => 'slave', master => '127.0.0.3', cas => $cas }), "Change domain to be SLAVE");
is($r->{domain}->{type}, 'SLAVE', 'now slave');
isnt($r->{domain}->{cas}, $cas, "Got new cas value");
$cas = $r->{domain}->{cas};

ok($r = api_call(POST => "domain/$domain", { type => 'master', cas => $cas }), "Change domain back to be master");
is($r->{domain}->{type}, 'MASTER', 'now master');

diag("old cas: $cas");
pp($r);
done_testing();
exit;

ok($r = api_call(POST => "record/$domain", { type => 'NS', name => '', content => 'ns1.example.com' }), 'setup NS record');
ok($r->{record}->{id}, 'got an ID');
is($r->{record}->{type}, 'NS', 'is an NS record');

# check that we got a new domain cas

# try posting a record with wrong cas

# post again with the right cas
ok($r = api_call(POST => "record/$domain", { type => 'A', name => 'www', content => '10.0.0.1' }), 'setup A record');
ok($r->{record}->{id}, 'got an ID');
is($r->{record}->{content}, '10.0.0.1', 'correct content');

# try deleting a record with wrong cas
 

# delete a record with the right cas


# check that the domain is setup correctly and that the domain comes back with the expected cas from the last update


