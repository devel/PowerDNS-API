package PowerDNS::API::Controller;
use strict;
use Mojo::Base 'Mojolicious::Controller';

use JSON::XS ();
my $json = JSON::XS->new->convert_blessed->pretty;

sub schema {
    return shift->app->schema;
}

sub render_json {
    my ($self, $data, $status) = @_;
    $status ||= 200;
    $self->res->headers->content_type('application/json');
    $self->render_text($json->encode($data), status => $status);
}

sub auth {
    my $self = shift;
    my $rv = $self->basic_auth(
        'PowerDNS::API' => sub {
            my ($username, $password) = @_;
            #warn "USER/PASS", $username, $password;
            return unless $username;
            my $account = $self->app->schema->account->find({name => $username})
              or return;

            #warn "Got account ", $account->id, if $account;

            $self->stash('account', $account);

            return 1 if $account and $account->check_password($password);
            return 0;
        }
    );
    return $rv if $rv;
    return;
}

1;
