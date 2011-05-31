package PowerDNS::API::Handler::API;
use Dancer ':syntax';
use Moose;
extends 'PowerDNS::API::Handler';

use JSON qw(encode_json);
use namespace::clean;

sub schema { return PowerDNS::API::schema() }

prefix '/api';

set serializer => 'JSONC';

use Dancer::Plugin::REST;

get '/domain/:domain?' => \&_get_domain;
sub _get_domain {

    my $account = vars->{account} or return status_unauthorized("unauthorized");

    my $id = params->{domain} || '';
    
    {
        my $x = "getting domain: [$id]";
        $Test::More::VERSION ? Test::More::diag($x) : debug($x);
    }

    if ($id eq '') {
        my $domains = schema->domain->search({ account => $account->name });
        my $data = [];
        while (my $domain = $domains->next) {
            push @$data, $domain;
        }
        return status_ok({ domains => $data });
    }

    # we're just working on one domain
    my $domain = schema->domain->find({ name => $id })
      or return status_not_found("domain doesn't exist");

    return status_unauthorized("unauthorized")
      unless $account->has_access( $domain );

    return status_ok({ domain => $domain,
                       records => _records($domain, scalar params)
                     }
                    );

}

sub _records {
    my ($domain, $options) = @_;

    my @args = qw(name type content);
    my %args = map { $_ => $options->{$_} } grep { defined $options->{$_} } @args;
    
    if (defined $args{name}) {
        $args{name} = $domain->clean_hostname($args{name});
    }
    
    my $records = schema->record->search({ %args,
                                           domain_id => $domain->id
                                         });

    my $data = $records ? [ $records->all ] : undef;

   return $data;

}

sub _soa_fields {
    return qw(primary hostmaster serial refresh retry expire default_ttl);
}

put '/domain/:domain?' => \&_put_domain;
sub _put_domain {

    my $account = vars->{account} or return status_unauthorized("unauthorized");

    my $name = params->{domain} or return status_bad_request();
    # check permissions

    {
        my $domain = schema->domain->find({ name => $name });
        return status_conflict("domain exists") if $domain;
    }

    {
        my $top_domain = $name;
        while ($top_domain =~ s/.*?\.//) {
            my $domain = schema->domain->find({ name => $top_domain });
            return status_forbidden("subdomain of another account")
              if $domain and $domain->account->name ne $account->name;
        }
    }

    my $data = {};
    for my $f (qw(master type)) {
        $data->{$f} = params->{$f};
    }
    $data->{name} = $name;
    $data->{type} = 'MASTER'
      unless ($data->{type} and uc $data->{type} eq 'SLAVE');

    $data->{type} = uc $data->{type};

    if ($data->{type} eq 'SLAVE') {
        return status_bad_request('master parameter required for slave domains')
          unless $data->{master};
    }

    $data->{account} = $account->name;

    my $domain = schema->domain->create($data);
    $domain->soa( params ) unless $domain->type eq 'SLAVE';

    return status_created({ domain => $domain });
}


post '/domain/:domain?' => \&_post_domain;
sub _post_domain {

    my $account = vars->{account} or return status_unauthorized("unauthorized");

    my $domain_name = params->{domain} or return status_bad_request();

    my $domain = schema->domain->find({ name => $domain_name })
      or return status_not_found("domain not found");

    return status_unauthorized("unauthorized")
      unless $account->has_access($domain);

    my $txn = schema->txn_scope_guard;

    my $data = {};
    for my $f (qw(master type)) {
        next unless defined params->{$f};
        $domain->$f(uc params->{$f});
    }
    if ($domain->type eq 'SLAVE') {
        return status_bad_request("master required for slave domains")
          unless $domain->master;
    }
    
    $domain->update;
    $domain->increment_serial;

    $txn->commit;

    return status_ok({ domain => $domain });
}

put '/record/:domain/:id' => \&_put_record;
sub _put_record {
    my $account = vars->{account} or return status_unauthorized("unauthorized");

    my $domain_name = params->{domain} or return status_bad_request();
    my $record_id   = params->{id} or return status_bad_request("record id required");

    my $domain = schema->domain->find({ name => $domain_name })
      or return status_not_found("domain not found");

    return status_unauthorized("unauthorized")
      unless $account->has_access($domain);

    return status_method_not_allowed("Can't modify a SLAVE domain")
      if uc $domain->type eq 'SLAVE';

    my $record = schema->record->find({ id => $record_id, domain_id => $domain->id })
      or return status_not_found("record not found");

    # TODO:
      # parse parameters as approprate for each type
      # support specific names per data type as appropriate (rather than just 'content')

    for my $f ( qw( type name content ttl prio ) ) {
        $record->$f( params->{$f} ) if defined params->{$f};
    }

    $record->update;
    $domain->increment_serial;

    return status_accepted( { record => $record, domain => $domain } );

}

post '/record/:domain' => \&_post_record;
sub _post_record {

    my $account = vars->{account} or return status_unauthorized("unauthorized");

    use Data::Dump qw(pp);
    debug ("foo: " . pp( { params => scalar params } ));

    my $domain_name = params->{domain} or return status_bad_request();

    my $domain = schema->domain->find({ name => $domain_name })
      or return status_not_found("domain not found");

    return status_unauthorized("unauthorized")
      unless $account->has_access($domain);

    return status_method_not_allowed("Can't modify a SLAVE domain")
      if uc $domain->type eq 'SLAVE';

    for my $f (qw( type name content ) ) {
        defined params->{$f}
          or return status_bad_request("$f is required")
    }

    my $txn = schema->txn_scope_guard;

    my $data = {};
    for my $f (qw( type name content ttl prio ) ) {
        next unless defined params->{$f};
        $data->{$f} = params->{$f};
    }
    $data->{type} = uc $data->{type};
    $data->{name} = $domain->clean_hostname( $data->{name} );
    unless (defined $data->{ttl}) {
        $data->{ttl} = $data->{type} eq 'NS' ? 86400 : 7200;
    }

    $data->{change_date} = time;

    my $record = $domain->add_to_records($data);
    $domain->increment_serial;

    $txn->commit;

    return status_created({ domain => $domain, record => $record } );

};

del '/record/:domain/:id' => \&_del_record;
sub _del_record {
    my $account = vars->{account} or return status_unauthorized("unauthorized");

    my $domain_name = params->{domain} or return status_bad_request();
    my $record_id   = params->{id} or return status_bad_request("record id required");

    my $domain = schema->domain->find({ name => $domain_name })
      or return status_not_found("domain not found");

    return status_unauthorized("unauthorized")
      unless $account->has_access($domain);

    return status_method_not_allowed("Can't modify a SLAVE domain")
      if uc $domain->type eq 'SLAVE';

    my $record = schema->record->find({ id => $record_id, domain_id => $domain->id })
      or return status_not_found("record not found");

    my $txn = schema->txn_scope_guard;

    $record->delete;
    $domain->increment_serial;

    $txn->commit;

    return status_ok({ message => "record deleted", domain => $domain });

}

1;
