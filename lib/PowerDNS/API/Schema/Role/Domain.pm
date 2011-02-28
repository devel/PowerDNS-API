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
        $args->{serial} ||= 1;
    }
    if ($args && %$args) {
        for my $f ($record->fields) {
            warn "f: $f";
            warn "v: ", $args->{$f} if defined $args->{$f};
            $record->$f($args->{$f}) if exists $args->{$f};
        }
        $record->insert_or_update;
    }

    #Test::More::diag( Data::Dump::pp( $record->data ) );

    return $record;
}

sub increment_serial {
    my $self = shift;
    my $soa = $self->soa;
    warn "REF SOA: ", ref $soa;
    my $serial = $soa->serial || 0;
    warn "serial: ", $serial;

    $soa->serial( ++$serial );
    $soa->update;

    $serial;

}

1;

