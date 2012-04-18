package PowerDNS::API::Handler;
use Mojo::Base 'PowerDNS::API::Controller';
use Moose;
use Data::Dump qw(pp);
use Try::Tiny;

use namespace::clean;

sub handle_request {
    my $self = shift;

    my $handler = $self->stash('api_handler');

    try {
        $self->$handler(@_);
    }
    catch {
        my $e = $_;
        if (ref $e eq 'ARRAY' and ref $e->[0] eq 'HASH' and $e->[0]->{error}) {
            return $self->render_json($e->[0], ( $e->[1] || 500 ));
        }
        die $e;
    }
}

sub _check_cas {
    my $self = shift;
    my $domain = shift;
    my $req_cas = $self->param('cas');
    if ($req_cas and $req_cas ne $domain->cas) {
        die $self->render_error(409, "wrong cas value");
    }
}

sub get_domain {
    my $self = shift;

    my $account = $self->stash('account') or die $self->render_error(401, "unauthorized");

    my $id = $self->stash('domain') || '';

    if ($id eq '') {
        my $domains = $self->schema->domain->search({ account => $account->name });
        my $data = [];
        while (my $domain = $domains->next) {
            push @$data, $domain->TO_JSON;
        }
        return $self->render_json({ domains => $data });
    }

    # we're just working on one domain
    my $domain = $self->schema->domain->find({ name => $id })
      or die $self->render_error(404, "domain doesn't exist");

    die $self->render_error(401, "unauthorized")
      unless $account->has_access( $domain );

    return $self->render_json(
        {   domain  => $domain,
            records => $self->_records($domain, $self->req->params->to_hash)
        },
        200
    );
}

sub _records {
    my $self = shift;
    my ($domain, $options) = @_;

    my @args = qw(name type content id);
    my %args = map { $_ => $options->{$_} } grep { defined $options->{$_} } @args;
    
    if (defined $args{name}) {
        $args{name} = $domain->clean_hostname($args{name});
    }
    
    my $records = $self->schema->record->search({ %args,
                                           domain_id => $domain->id
                                         });

    my $data = $records ? [ $records->all ] : undef;

   return $data;

}

sub put_domain {
    my $self = shift;

    my $account = $self->stash('account') or die $self->render_error(401, "unauthorized");

    my $name = lc $self->stash('domain') or die $self->render_error(400);

    my $txn = $self->schema->txn_scope_guard;

    {
        my $domain = $self->schema->domain->find({ name => $name }, { for => 'update' });
        die $self->render_error(409, "domain exists") if $domain;
    }

    {
        my $top_domain = $name;
        while ($top_domain =~ s/.*?\.//) {
            my $domain = $self->schema->domain->find({ name => $top_domain });
            die $self->render_error(403, "subdomain of another account")
              if $domain and $domain->account->name ne $account->name;
        }
    }

    my $data = {};
    for my $f (qw(master type)) {
        $data->{$f} = $self->param($f);
    }
    $data->{name} = $name;
    $data->{type} = 'MASTER'
      unless ($data->{type} and uc $data->{type} eq 'SLAVE');

    $data->{type} = uc $data->{type};

    if ($data->{type} eq 'SLAVE') {
        die $self->render_error(400,'master parameter required for slave domains')
          unless $data->{master};
    }

    $data->{account} = $account->name;

    my $domain = $self->schema->domain->create($data);

    $domain->soa( $self->req->params->to_hash ) unless $domain->type eq 'SLAVE';

    $txn->commit;

    return $self->render_json({ domain => $domain }, 201);
}

sub render_error {
    my ($self, $status, $error) = @_;
    return [ { error => $error }, $status ];
}

sub post_domain {
    my $self = shift;

    my $account = $self->stash('account') or die $self->render_error(401, "unauthorized");

    my $domain_name = $self->stash('domain') or die $self->render_error(400);

    my $txn = $self->schema->txn_scope_guard;

    my $domain = $self->schema->domain->find({ name => $domain_name }, { for => 'update' })
      or die $self->render_error("domain not found", 404);

    die $self->render_error(401, "unauthorized")
      unless $account->has_access($domain);

    $self->_check_cas($domain);

    my $data = {};
    for my $f (qw(master type)) {
        next unless defined $self->param($f);
        $domain->$f(uc $self->param($f));
    }
    if ($domain->type eq 'SLAVE') {
        die $self->render_error(400,"master required for slave domains")
          unless $domain->master;
    }

    $domain->update;
    $domain->increment_serial;

    $txn->commit;

    return $self->render_json({ domain => $domain });
}

sub put_record {
    my $self = shift;

    my $account = $self->stash('account') or die $self->render_error(401, "unauthorized");

    my $domain_name = $self->stash('domain') or die $self->render_error(400);
    my $record_id   = $self->stash('id') or die $self->render_error(400, "record id required");

    my $txn = $self->schema->txn_scope_guard;

    my $domain = $self->schema->domain->find({ name => $domain_name }, { for => 'update' })
      or die $self->render_error(404, "domain not found");

    die $self->render_error(401, "unauthorized")
      unless $account->has_access($domain);

    die $self->render_error(405, "Can't modify a SLAVE domain")
      if uc $domain->type eq 'SLAVE';

    $self->_check_cas($domain);

    my $record = $self->schema->record->find({ id => $record_id, domain_id => $domain->id })
      or die $self->render_error(404, "record not found");

    # TODO:
      # parse parameters as appropriate for each type
      # support specific names per data type as appropriate (rather than just 'content')

    for my $f ( qw( type content ttl prio ) ) {
        $record->$f( $self->param($f) ) if defined $self->param($f);
    }

    if (my $name = $self->param('name')) {
        $record->name($domain->clean_hostname($name));
    }

    $record->update;
    $domain->increment_serial;

    $txn->commit;

    return $self->render_json( { record => $record, domain => $domain }, 202);

}

sub post_record {
    my $self = shift;

    my $account = $self->stash('account') or die $self->render_error(401, "unauthorized");

    #use Data::Dump qw(pp);
    #warn ("foo: " . pp( { params => $self->req->params } ));

    my $domain_name = $self->stash('domain') or die $self->render_error(400);

    my $txn = $self->schema->txn_scope_guard;

    my $domain = $self->schema->domain->find({ name => $domain_name }, { for => 'update' })
      or die $self->render_error(404, "domain not found");

    die $self->render_error(401, "unauthorized")
      unless $account->has_access($domain);

    die $self->render_error(405, "Can't modify a SLAVE domain")
      if uc $domain->type eq 'SLAVE';

    $self->_check_cas($domain);

    for my $f (qw( type name content ) ) {
        defined $self->param($f)
          or die $self->render_error(400,"$f is required")
    }

    die $self->render_error(406, "Can't create a second SOA record")
      if uc $self->param('type') eq 'SOA';

    my $data = {};
    for my $f (qw( type name content ttl prio ) ) {
        next unless defined $self->param($f);
        $data->{$f} = $self->param($f);
    }
    $data->{type} = uc $data->{type};
    $data->{name} = lc $domain->clean_hostname( $data->{name} );
    unless (defined $data->{ttl}) {
        $data->{ttl} = $data->{type} eq 'NS' ? 86400 : 7200;
    }

    $data->{change_date} = time;

    my $record = $domain->add_to_records($data);
    $domain->increment_serial;

    $txn->commit;

    return $self->render_json({ domain => $domain, record => $record }, 201);
};

sub delete_record {
    my $self = shift;

    my $account = $self->stash('account') or die $self->render_error(401, "unauthorized");

    my $domain_name = $self->stash('domain') or die $self->render_error(400,);
    my $record_id   = $self->stash('id') or die $self->render_error(400,"record id required");

    my $txn = $self->schema->txn_scope_guard;

    my $domain = $self->schema->domain->find({ name => $domain_name }, { for => 'update' })
      or die $self->render_error(404, "domain not found");

    die $self->render_error(401, "unauthorized")
      unless $account->has_access($domain);

    die $self->render_error(405, "Can't modify a SLAVE domain")
      if uc $domain->type eq 'SLAVE';

    $self->_check_cas($domain);

    my $record = $self->schema->record->find({ id => $record_id, domain_id => $domain->id })
      or die $self->render_error(404, "record not found");

    $record->delete;
    $domain->increment_serial;

    $txn->commit;

    return $self->render_json({ message => "record deleted", domain => $domain }, 205);

}

1;
