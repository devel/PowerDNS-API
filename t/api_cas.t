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

$TestUtils::current_user = $account;

ok(my $r = api_call(PUT => "domain/$domain", { serial => 3, user => $account }), 'setup new domain');
$t->status_is( 201, 'ok, created');
ok(my $cas = $r->{domain}->{cas}, 'got cas value');

ok($r = api_call(GET => "domain/$domain", { foo => 123 }), "Get domain");
ok($r->{domain}, "got domain back");
is($r->{domain}->{name}, $domain, 'got the right domain');
is($r->{domain}->{cas}, $cas, "got the same cas value ($cas)");

ok( $r = api_call(POST => "domain/$domain",
    {type => 'slave', master => '127.0.0.3', cas => 'wrong'}),

    "Change domain to be SLAVE, wrong cas value"
);
$t->status_is( 409, 'conflict, wrong cas');

ok($r = api_call(POST => "domain/$domain", { type => 'slave', master => '127.0.0.3', cas => $cas }), "Change domain to be SLAVE");
is($r->{domain}->{type}, 'SLAVE', 'now slave');
isnt($r->{domain}->{cas}, $cas, "Got new cas value");
$cas = $r->{domain}->{cas};

ok($r = api_call(POST => "domain/$domain", { type => 'master', cas => $cas }), "Change domain back to be master");
is($r->{domain}->{type}, 'MASTER', 'now master');
isnt($r->{domain}->{cas}, $cas, "Got new cas value");
ok($cas = $r->{domain}->{cas}, "got cas");

ok($r = api_call(POST => "record/$domain", { type => 'NS', name => '', content => 'ns1.example.com', cas => $cas }), 'setup NS record');
ok(my $ns_id = $r->{record}->{id}, 'got an ID');
is($r->{record}->{type}, 'NS', 'is an NS record');
isnt($r->{domain}->{cas}, $cas, "Got new cas value");
ok($cas = $r->{domain}->{cas}, "got cas");

ok($r = api_call(POST => "record/$domain", { type => 'NS', name => '', content => 'ns2.example.com', cas => 'wrong' }), 'setup NS record with wrong cas');
$t->status_is( 409, 'conflict, wrong cas');

ok($r = api_call(GET => "domain/$domain", { name => '', type => 'NS' } ), "Get NS records");
is(scalar @{ $r->{records} }, 1, "Got one record");
is($r->{records}->[0]->{content}, 'ns1.example.com', "Got the right record");

ok($r = api_call(PUT => "record/$domain/$ns_id", { type => 'NS', name => '', content => 'ns3.example.com', cas => 'wrong'}), 'replace NS record, wrong cas');
$t->status_is( 409, 'conflict, wrong cas');

# post again with the right cas
ok($r = api_call(PUT => "record/$domain/$ns_id", { type => 'NS', name => '', content => 'ns3.example.com', cas => $cas }), 'replace NS record');
is($r->{record}->{id}, $ns_id, 'got the same id');
is($r->{record}->{content}, 'ns3.example.com', 'correct content');
ok($cas = $r->{domain}->{cas}, "got cas");

ok($r = api_call(DELETE => "record/$domain/$ns_id", { cas => 'wrong'}), 'delete record, wrong cas');
$t->status_is( 409, 'conflict, wrong cas');
is($r->{error}, 'wrong cas value', 'got cas error');

ok($r = api_call(DELETE => "record/$domain/$ns_id", { cas => $cas }), 'delete record');
is($r->{message}, 'record deleted');
$t->status_is( 205, 'got 205 status code');
# is($r->{record}->{content}, 'ns3.example.com', 'correct content');
ok($cas = $r->{domain}->{cas}, "got cas");

ok($r = api_call(GET => "domain/$domain", {  } ), "Get all records");
is($r->{domain}->{cas}, $cas, 'got the right cas');
is(scalar @{ $r->{records} }, 1, "Got one record");
is($r->{records}->[0]->{type}, 'SOA', "Got the SOA record");

$account->delete;

done_testing();





