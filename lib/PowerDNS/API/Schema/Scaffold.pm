package PowerDNS::API::Schema::Scaffold;
use Moose;
extends 'Mesoderm';

my %no_serialize = (
   accounts => [ qw( id password api_secret api_key ) ],
   domains  => [ qw( notified_serial last_check ) ],
);


override column_info => sub {
    my ($self, $column) = @_;
    my $info = super;
    $info->{serializer_class} = 'JS' if $column->name eq 'notes';

    if ($column->{data_type} =~ m/(DATE|TIME)/) {
        $info->{timezone} = 'UTC';
    }

    if (my $columns = $no_serialize{ $column->table->name } ) {
        my $column_name = $column->name;
        $info->{is_serializable} = 0 
          if grep { $_ eq $column_name } @$columns; 
    }

    return $info;
};

override column_accessor => sub {
    my ($self, $column) = @_;
    return "_cas" if $column->name eq 'cas' and $column->table->name eq 'domains';
    return super;
};

override column_components => sub {
    my ($self, $column) = @_;
    my @components = super;
    push @components, 'InflateColumn::Serializer' if $column->name eq 'notes';
    return @components;
};

override table_components => sub {
    my ($self, $table) = @_;
    my @components = super;
    push @components, 'Helper::Row::ToJSON';
    return @components;
};

1;

