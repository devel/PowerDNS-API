use Test::More tests => 2;
use strict;
use warnings;
use lib 't';

use TestUtils;
use Test::Mojo;

my $t = Test::Mojo->new('PowerDNS::API');
$t->get_ok('/')->status_is(200);
