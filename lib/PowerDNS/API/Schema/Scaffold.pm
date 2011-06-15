package PowerDNS::API::Schema::Scaffold;
use Moose;
extends 'MooseX::DBIC::Scaffold';

override column_info => sub {
    my ($self, $column) = @_;
    my $info = super;
    $info->{serializer_class} = 'JS' if $column->name eq 'notes';

    if ($column->{data_type} =~ m/(DATE|TIME)/) {
        $info->{timezone} = 'UTC';
    }

    $info->{is_serializable} = 0 
      if $column->name =~ m/^(password|api_secret)$/;

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

