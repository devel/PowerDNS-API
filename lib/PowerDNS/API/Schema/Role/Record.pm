package PowerDNS::API::Schema::Role::Record;
use Moose::Role;

sub TO_JSON {
    my $self = shift;

    my $data = { 
                map +($_ => $self->$_),
                @{$self->serializable_columns}
               };
    
    my $domain = $self->domain->name;
    
    $data->{name} =~ s{\Q$domain\E$}{};
    $data->{name} =~ s{\.$}{};

    return $data;
}

1;
