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

    return $info;
};

override column_components => sub {
    my ($self, $column) = @_;
    my @components = super;
    push @components, 'InflateColumn::Serializer' if $column->name eq 'notes';
    return @components;
};

1;

