package PowerDNS::API::Schema::Role::Domain;
use Moose::Role;

sub clean_hostname {
    my ($domain, $name) = @_;
    my $domain_name = lc $domain->name;
    $name .= ( $name ? "." : "" ) . $domain->name;
    return $name;
}

sub soa {
    my $self   = shift;
    my $args   = ref $_[0] ? shift : { @_ };
    my $schema = PowerDNS::API::Schema->instance;
    my $record = $schema->record->find
      (
       {   type      => 'SOA',
           domain_id => $self->id
       }
      );

    return $record if $self->type eq 'SLAVE';

    unless ($record) {
        $record = $schema->record->new(
            {   domain_id   => $self->id,
                name        => $self->name,
                type        => 'SOA',
                change_date => time,
            }
        );
    }
    if ($args && %$args) {
        for my $f ($record->fields) {
            $record->$f($args->{$f}) if exists $args->{$f};
        }
        $record->update_or_insert;
    }
    return $record;
}

1;

