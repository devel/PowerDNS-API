package PowerDNS::API::Schema::Role::Domain;
use Moose::Role;

sub clean_hostname {
    my ($domain, $name) = @_;
    my $domain_name = lc $domain->name;
    $name .= ( $name ? "." : "" ) . $domain->name;
    return $name;
}

1;

