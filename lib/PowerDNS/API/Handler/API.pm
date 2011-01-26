package PowerDNS::API::Handler::API;
use strict;
use base qw(PowerDNS::API::Handler);
use JSON qw(encode_json);
use namespace::clean;

sub _parse {
    my $self = shift;
    return $self->{_p} ||= do {
        my $path = $self->request->path;
        $path =~ s!^/api/!!;

        my ($domain_name, $record_id) = ( $path =~ m!([^/]+)(?:/([^/]+))?! );
        
        return { path        => $path,
                 domain_name => $domain_name,
                 record_id   => $record_id,
               }
    };
}

sub r_path {
    shift->_parse->{path};
}

sub r_domain_name {
    shift->_parse->{domain_name};
}

sub r_record_id {
    shift->_parse->{record_id} || '';
}


sub get {
    my $self = shift;

    use Data::Dump qw(pp);

    $self->{foo} ||= 0;
    warn "foo: ", $self->{foo}++;

    #pp($self, \@_);

    my $path = $self->r_path;

    if ($path eq '_all') {
        # TODO: only do the appropriate accounts
        my $domains = $self->schema->domain->search();
        my $data = [];
        while (my $domain = $domains->next) {
            push @$data, $domain;
        }
        $self->write($self->json->encode({ domains => $data }));
        return $self->finish;
    }

    #xxx
    return 404 unless $domain_name;
    $record_id ||= '';

    # we're just working on one domain
    my $domain = $self->schema->domain->find({ name => $domain_name })
      or return 404;

    my $data = { domain => $domain };

    my $records;
    
    if ($record_id eq '_all') {
        $records = $self->schema->record->search({ domain_id => $domain->id });
    }
    else {
        my @args = qw(name type content);
        my $v    = $self->request->query_parameters;
        my %args = map { $_ => $v->{$_} } grep { defined $v->{$_} } @args;
        
        if (defined $args{name}) {
            my $domain_name = lc $domain->name;
            $args{name} = $domain_name if $args{name} eq '';
            $args{name} .= "." . $domain_name
              if ( $args{name} !~ m/\.\Q$domain_name\E$/i
                   and lc $args{name} ne $domain_name);
        }

        $records = $self->schema->record->search({ %args,
                                                   domain_id => $domain->id
                                                 });
        
    }

    $data->{records} = [ $records->all ] if $records;

    $self->write($self->json->encode($data));
    $self->finish;

}

sub put {

    

    # check permissions

    # domain ?
      # setup domain

    # record ?
      # add record
      # bump serial
}

sub post {
    # parse request
    # check permissions

    # domain ?
      # allow updating type
      #   if slave, allow changing master setting (but require it to be set)

    # record ?
      # require id
      # allow updating types:
      #   A, AAAA, CNAME, MX, NS, PTR, RP, SRV, TXT, SOA
      # parse parameters for each 
      # generic 'data' when appropriate, specific names when needed

}

sub delete {
    # parse request
    # check permissions

    # don't allow deleting domains for now?

    # records
    #   require id

}

1;
