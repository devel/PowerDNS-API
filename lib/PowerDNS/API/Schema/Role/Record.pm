package PowerDNS::API::Schema::Role::Record;
use Moose::Role;
use Class::MOP;

# http://doc.powerdns.com/types.html

my %types = (
    'SOA' => 'PowerDNS::API::Schema::Record::SOA',
    'A'   => 'PowerDNS::API::Schema::Record::A',
);

sub load_type_classes {
    for my $class (values %types) {
        Class::MOP::load_class($class);
    }
}

# todo: merge with 'inflate_result'
around 'new' => sub {
    my $orig = shift;
    my $r = $orig->(@_);
    if (my $class = $types{$r->type}) {
        bless $r, $class
    }
    return $r;
};

around 'inflate_result' => sub {
    my $orig = shift;
    my $r = $orig->(@_);
    if (my $class = $types{$r->type}) {
        bless $r, $class
    }
    return $r;
};

around [ 'update', 'insert' ] => sub {
    my $orig = shift;
    my $self = shift;
    my $content = $self->format_content;
    $self->content($content);
    $orig->($self, @_);
};

has 'data' => (
    is => 'ro',
    lazy_build => 1,
);

sub _build_data {
    shift->content;
}

sub format_content {
    shift->data;
}

sub fields { return () }

sub TO_JSON {
    my $self = shift;

    my $data = { 
                map +($_ => $self->$_),
                @{$self->serializable_columns}, $self->fields
               };
    
    my $domain = $self->domain->name;
   
    $data->{name} =~ s{\Q$domain\E$}{};
    $data->{name} =~ s{\.$}{};

    return $data;
}

1;
