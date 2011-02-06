package PowerDNS::API::Schema::Role::Record;
use Moose::Role;

# http://doc.powerdns.com/types.html

sub _parse_soa {
    my $self = shift;
    my %data;
    @data{qw(primary hostmaster serial refresh retry expire default_ttl)} = split /\s+/, $self->content;
    return \%data;
}

sub TO_JSON {
    my $self = shift;

    my $data = { 
                map +($_ => $self->$_),
                @{$self->serializable_columns}
               };
    
    my $domain = $self->domain->name;
   
    $data->{name} =~ s{\Q$domain\E$}{};
    $data->{name} =~ s{\.$}{};

    my $m = "_parse_" . lc $self->type;
    if ($self->can($m)) {
        $data->{data} = $self->$m;
    }
    else {
        $self->{data} = $self->content;
    }

    return $data;
}

1;
