package PowerDNS::API::Home;
use Mojo::Base 'PowerDNS::API::Controller';

sub welcome {
  my $self = shift;

  $self->render(
    message => 'Welcome to the PowerDNS HTTP API'
  );

}

1;
