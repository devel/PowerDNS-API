package PowerDNS::API::Schema::Role::Domain;
use Moose::Role;

1;


__END__

 sub TO_JSON {
    my $self = shift;

    return {
       customer_name => $self->customer->name,
            %{ $self->next::method },
    }
}
