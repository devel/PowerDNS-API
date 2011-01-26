package PowerDNS::API::Application;
use Tatsumaki::Application;
use base qw(Tatsumaki::Application);
use Moose;
use File::Basename qw(dirname);
use PowerDNS::API::Handler::Main;
use PowerDNS::API::Handler::API;
use AnyEvent;

use namespace::clean;

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    return $class->$orig(['/'    => 'PowerDNS::API::Handler::Main',
                          '/api' => 'PowerDNS::API::Handler::API',
                          @_]);
};

sub BUILD {
    my $app = shift;
    $app->template_path(dirname(__FILE__) . "/templates");
    $app->static_path(dirname(__FILE__) . "/static");
    $app
}


1;
