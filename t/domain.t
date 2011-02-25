use Test::More;
use strict;
use warnings;
use Data::Dump qw(pp);
use lib 't';

use PowerDNS::API::Schema;
use Dancer::Test;

use TestUtils;

my $schema = PowerDNS::API::Schema->new;

ok(my $domain = $schema->domain->create({ name => "domain-" . time . ".test",
      type => 'MASTER'
       }), "new domain");

my $soa = $domain->soa;


done_testing();
