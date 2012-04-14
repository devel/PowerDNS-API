package PowerDNS::API::Schema::Role::Domain;
use Moose::Role;

sub clean_hostname {
    my ($domain, $name) = @_;
    my $domain_name = lc $domain->name;
    $name .= ( $name ? "." : "" ) . $domain->name;
    return $name;
}

#after 'create' => sub {
#    shift->update_cas;
#};

sub soa {
    my $self   = shift;
    my $args   = ref $_[0] ? shift : { @_ };
    my $schema = PowerDNS::API::Schema->instance;
    my $record = $schema->record->single
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
        #warn "RECORD REF ", ref $record;
        $args->{serial} ||= 1;
    }
    if ($args && %$args) {
        for my $f ($record->fields) {
            #warn "f: $f";
            #warn "v: ", $args->{$f} if defined $args->{$f};
            $record->$f($args->{$f}) if exists $args->{$f};
        }
        $args->{ttl} ||= $record->data->{default_ttl};
        $record->ttl($args->{ttl});
        $record->insert_or_update;
    }

    #Test::More::diag( Data::Dump::pp( $record->data ) );

    return $record;
}

sub cas {
    my $self = shift;
    my $cas = $self->_cas;
    return $cas if $cas;
    return $self->update_cas;
}

sub update_cas {
    my $self = shift;
    # TODO: Use Math::Random or some such here; base36 encode the
    # result

    my $old_cas = $self->_cas || 'undefined';

    my $cas = $self->_cas( substr( rand, 3, 10 ) );

    $self->update; # does this make sense?
    return $cas;
}

sub increment_serial {
    my $self = shift;
    my $soa = $self->soa;
    my $serial = $soa->serial || 0;
    $soa->serial( ++$serial );
    $soa->update;

    $self->update_cas;

    $serial;
}

1;

