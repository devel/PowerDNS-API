use Test::More;
use strict;
use warnings;
use Data::Dump qw(pp);

# the order is important
require PowerDNS::API;
use Dancer::Test;

use lib 't';
use TestUtils;

my $domain = "abc-" . time . "-". int(rand(9)) . ".test";
my $slave_domain = "slave-$domain";

my $r;

ok($r = api_call(PUT => "domain/$slave_domain", { type => 'slave' } ), 'setup new slave domain, no master');
is($r->{r}->{status}, 400, 'master parameter required');

ok($r = api_call(PUT => "domain/$slave_domain", { type => 'slave', master => '127.0.0.2' } ),
       'setup new slave domain');
is($r->{r}->{status}, 201, 'ok, created');

ok($r = api_call(PUT => "domain/$domain"), 'setup new domain');
is($r->{r}->{status}, 201, 'ok, created');
# diag pp($r);

ok($r = api_call(PUT => "domain/$domain"), 'setup the same domain again');
is($r->{r}->{status}, 409, 'domain already exists');
like($r->{error}, qr/domain exists/, 'got error message');

ok($r = api_call(GET => "domain/$domain"), "Get domain");
ok($r->{domain}, "got domain back");
is($r->{domain}->{name}, $domain, 'got the right domain');
is($r->{domain}->{type}, 'MASTER', 'new domain got setup as master');

ok($r = api_call(POST => "domain/$domain", { type => 'slave', master => '127.0.0.3' }), "Change domain to be SLAVE");
is($r->{domain}->{type}, 'SLAVE', 'now slave');

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

ok($r = api_call(DELETE => "record/$domain/$id"), 'delete TXT record');


$id = $r->{record}->{id};


diag pp($r);

done_testing();
