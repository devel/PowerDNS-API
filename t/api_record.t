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

my $r;

my $schema = $t->app->schema;

my $domain = test_domain_name;

ok(my $account  = setup_user, 'setup account');
ok(my $account2 = setup_user, 'setup account 2');

$TestUtils::current_user = $account;

ok($r = api_call(PUT => "domain/$domain", { user => $account }), 'setup new domain');
$t->status_is(201, 'ok, created');

ok($r = api_call(POST => "record/$domain", { type => 'NS', name => '', content => 'ns1.example.com' }), 'setup NS record');
$t->status_is(201);
ok($r->{record}->{id}, 'got an ID');
is($r->{record}->{type}, 'NS', 'is an NS record');

ok($r = api_call(POST => "record/$domain", { type => 'SOA', name => '', content => '' }), 'Add a second SOA record');
$t->status_is(406);

ok($r = api_call(POST => "record/$domain", { type => 'A', name => 'wwW', content => '10.0.0.1' }), 'setup A record');
ok($r->{record}->{id}, 'got an ID');
is($r->{record}->{content}, '10.0.0.1', 'correct content');
is($r->{record}->{name}, 'www', 'return lower-case name');
is($r->{record}->{address}, '10.0.0.1', 'A record also has "address"');

my $id = $r->{record}->{id};

ok($r = api_call(PUT => "record/$domain/$id", { content => '10.0.0.2' }), 'change A record, content');
is($r->{record}->{content}, '10.0.0.2', 'correct content');

ok($r = api_call(PUT => "record/$domain/$id", { name => 'www.FOO' }), 'change A record, name');
is($r->{record}->{content}, '10.0.0.2', 'correct content');
is($r->{record}->{name}, 'www.foo', 'correct name');

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
ok($id = $r->{record}->{id}, 'got an ID');
is($r->{record}->{ttl}, 600, 'correct TTL');

ok($r = api_call(GET => "domain/$domain", { type => 'A' }), "Get records with filter");
ok($r->{domain}, "got domain back");
is($r->{domain}->{name}, $domain, 'got the right domain');
is($r->{records}->[0]->{name}, 'www.foo', 'got the right record name');
#diag pp($r->{records});

ok($r = api_call(DELETE => "record/$domain/$id"), 'delete TXT record');

$id = $r->{record}->{id};

ok($account->delete, 'deleted account again');
ok($account2->delete, 'deleted second account');

done_testing();
exit;
