package PowerDNS::API::Home;
use Mojo::Base 'PowerDNS::API::Controller';

sub welcome {
  my $self = shift;

  $self->render(
    message => 'Welcome to the PowerDNS HTTP API'
  );
}

sub ui {
    my $self = shift;
    $self->res->code(301);
    $self->redirect_to('/app/index.html');
}

1;
