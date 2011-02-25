package TestUtils;

use base 'Exporter';
use vars '@EXPORT';

use Dancer::Request;
use Dancer::Config 'setting';
use JSON qw(decode_json);

@EXPORT =
  qw(setup_user test_domain_name api_call fake_request get_response_for_request);

my $inc = 0;

sub setup_user {
    my $accountname = 'test.' . time . '.' . ++$inc;
    my $password    = rand;
    my $schema      = PowerDNS::API::schema();
    my $account =
      $schema->account->create({name => $accountname, password => $password});
}

sub test_domain_name {
    return "abc-" . time . "-". int(rand(9)) . ".test";
}

sub fake_request($$;$) {
    my ($method, $path, $params) = @_;
    my $req = Dancer::Request->new_for_request($method => $path);
    if ($params) {
        $req->_set_body_params($params);
    }
    if (my $user = delete $params->{user} || $P::current_user ) {
        $req->{env}->{REMOTE_USER} = ref $user ? $user->name : $user;
    }
    # Test::More::diag "REQ: ", Data::Dump::pp($req);
    return $req;
}

sub get_response_for_request {
    my ($method, $path, $params) = @_;
    my $request = fake_request($method => $path, $params);
    Dancer::SharedData->request($request);
    Dancer::Renderer::get_action_response();
}

sub api_call {
    my ($method, $call, $params) = @_;
    my $response = get_response_for_request($method, "/api/$call", $params);
    my $data = decode_json($response->{content});
    delete $response->{content};
    $data->{r} = $response;
    return $data;
}

1;

