use Test::More;
use strict;
use warnings;
use Data::Dump qw(pp);
use Net::DNS;

my $pdns_path = $ENV{PDNS_PATH}
  or plan skip_all => 'PDNS_PATH not set';

-x $pdns_path or plan skip_all => "$pdns_path is not executable";

use Test::Mojo;
my $t = Test::Mojo->new('PowerDNS::API');

$Carp::Verbose = 1;

use lib 't';
use TestUtils;

$TestUtils::t = $t;
my $port = 5734;

my $db_config = $t->app->config->{database};

diag "Config: ", pp($db_config);

my $pdns_pid = fork();
if (!$pdns_pid) {
   my @cmd = ($pdns_path, "--guardian=no", "--launch=gmysql", "--local-port=$port", "--socket-dir=/tmp");
   push @cmd, "--gmysql-user=$db_config->{user}" if $db_config->{user};
   push @cmd, "--gmysql-dbname=$db_config->{database}" if $db_config->{database};
   exec(@cmd);
   die "Could not exec " . join(" ", @cmd) . ": $!";
}

sleep 1;

my $res = Net::DNS::Resolver->new(
    nameservers => ['127.0.0.1'],
    debug       => 1,
    port        => $port,
    recurse     => 0
);

my $domain = test_domain_name;
my $slave_domain = "slave-$domain";

my $schema = $t->app->schema();
ok(my $account  = setup_user, 'setup account');
ok(my $account2 = setup_user, 'setup account 2');

$TestUtils::current_user = $account;

my $r;

ok($r = api_call(PUT => "domain/$domain", { user => $account }), 'setup new domain');
$t->status_is(201, 'ok, created');

diag(pp($r->{domain}));

{
    my $a = $res->send($domain, 'SOA');
    diag(pp($a));

    my $soa = ($a->answer)[0];
    isa_ok($soa, 'Net::DNS::RR', 'DNS answer is a Net::DNS::RR');

    is($soa->name, $domain, "got right domain name back") ;
    my $dns_serial = $soa->serial;
    diag("dns serial", $dns_serial);
    is($dns_serial, $r->{domain}->{soa}->{serial}, "got serial");
}

# diag pp($r);

$account->delete;
$account2->delete;

END {
    return unless $pdns_pid;
    diag "Killing $pdns_pid";
    kill 1, $pdns_pid;
    waitpid $pdns_pid, 0;
    exit 0;
}

done_testing();
