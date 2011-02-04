package PowerDNS::API::Schema::Role::Domain;
use Moose::Role;

sub clean_hostname {
    my ($domain, $name) = @_;
    my $domain_name = lc $domain->name;
    $name  = $domain_name if $name eq '';
    $name .= "." . $domain_name
      if ( $name !~ m/\.\Q$domain_name\E$/i
           and lc $name ne $domain_name);
    return $name;
}

1;


__END__

 sub TO_JSON {
    my $self = shift;

    return {
       customer_name => $self->customer->name,
            %{ $self->next::method },
    }
}
