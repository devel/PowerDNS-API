package TestUtils;
use strict;
use warnings;

use base 'Exporter';
use vars '@EXPORT';

use JSON qw(decode_json);

@EXPORT =
  qw(setup_user test_domain_name api_call fake_request get_response_for_request);

our ($t, $current_user);
my $inc = 0;

sub setup_user {
    my $accountname = 'test.' . time . '.' . ++$inc;
    my $password    = rand;
    my $schema      = PowerDNS::API::schema();
    my $account =
      $schema->account->create({name => $accountname, password => $password});
    $account->{__password} = $password;
    return $account;
}

my $domaincount = 0;
sub test_domain_name {
    return "abc-" . time . "-". ++$domaincount . int(rand(99)) . ".test";
}

sub get_response_for_request {
    my ($method, $path, $params) = @_;

    my $url = $t->ua->app_url;
    if (my $user = delete $params->{user} || $current_user) {
        $url->userinfo($user->name . ":" . $user->{__password});
    }
    $url->path($path);

    if ($method eq 'GET') {
        $url->query(%$params);
        return $t->get_ok($url);
    }
    if ($method eq 'DELETE') {
        $url->query(%$params);
        return $t->delete_ok($url);
    }
    elsif (uc $method =~ m/^(PUT|POST)/) {

        #warn "PATH: $path";
        my $tx = $t->ua->build_form_tx($path => $params);
        $tx->req->url($url);
        $tx->req->method($method);

        #warn "TX: ", Data::Dump::pp($tx);
        return $t->tx($t->ua->start($tx));
    }
    else {
        die "Don't know how to request with $method";
    }

}

sub api_call {
    my ($method, $call, $params) = @_;
    my $response = get_response_for_request($method, "/api/$call", $params)->tx->res;
    #warn "CONTENT: ", $response->body;
    my $data = eval { decode_json($response->body) } || {};
    $data->{r} = $response;
    return $data;
}

1;

