package PowerDNS::API;
use Mojo::Base 'Mojolicious';
#use PowerDNS::API::Handler::API;
use PowerDNS::API::Schema;
use Data::Dump ();

my $schema;
sub schema {
    my $self = shift;

    return $schema ||= do {
        my $db_config = $self->config->{database};
        PowerDNS::API::Schema->new(($db_config ? (config => $db_config) : ()));
    };

}

# This method will run once at server start
sub startup {
    my $self = shift;

    my $config =
      $self->plugin('JSONConfig',
        file => $ENV{POWERDNS_API_CONFIG} || $ENV{MOJO_CONFIG} || 'powerdns-api.conf');

    if ($config->{secret}) {
        $self->secret($config->{secret});
    }
    else {
        warn "'secret' not configured\n";
    }

    $self->plugin('BasicAuth');

    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer');

    # Router
    my $r  = $self->routes;
    my $ar   = $r->bridge('/')->to(action => 'auth');
    my $apir = $ar->to(controller => 'handler');

    my @api_handlers = (
        ['domain/*domain' => 'POST' => 'post_domain'],
        ['domain/*domain' => 'GET'  => 'get_domain'],
        ['domain/*domain' => 'PUT'  => 'put_domain'],

        ['record/*domain'     => 'POST' => 'post_record'],
        ['record/*domain/*id' => 'PUT'  => 'put_record'],
        ['record/*domain/*id' => 'DELETE' => 'delete_record'],
    );

    for my $h (@api_handlers) {
        my @h = @$h;
        $apir->route("/api/" . $h[0])->via($h[1])
          ->to(domain => '', action => 'handle_request', api_handler => $h[2], format => 'html')->name($h[2]);
    }

    # Normal route to controller
    $r->route('/')->to('example#welcome');
}

1;

__END__

=pod

=head1 NAME

PowerDNS::API - HTTP API to PowerDNS Data
 
=head1 DESCRIPTION


=head1 AUTHOR

Ask Bjørn Hansen, C<< <ask at develooper.com> >>

=head1 BUGS

Please report any bugs or feature requests to the issue tracker at
L<http://github.com/devel/PowerDNS-API/issues>.

The Git repository is available at
L<http://github.com/devel/PowerDNS-API>


=head1 COPYRIGHT & LICENSE

Copyright 2011 Ask Bjørn Hansen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
