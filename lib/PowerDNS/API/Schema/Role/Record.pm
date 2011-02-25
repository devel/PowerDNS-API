package PowerDNS::API::Schema::Role::Record;
use Moose::Role;
use Class::MOP;

# http://doc.powerdns.com/types.html

my %types = (
    'SOA' => 'PowerDNS::API::Schema::Record::SOA',
);

sub load_type_classes {
    for my $class (values %types) {
        Class::MOP::load_class($class);
    }
}

around 'new' => sub {
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
