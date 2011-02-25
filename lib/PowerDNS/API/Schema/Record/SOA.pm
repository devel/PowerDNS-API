package PowerDNS::API::Schema::Record::SOA;
use Moose;
extends 'PowerDNS::API::Schema::Record';

my @soa_fields = qw(primary hostmaster serial refresh retry expire default_ttl);

sub fields {
    return @soa_fields;
}

sub _build_data {
    my $self = shift;
    my %data;
    return {} unless $self->content;
    @data{@soa_fields} = split /\s+/, $self->content;
    return \%data;
}

sub format_content {
    my $self = shift;
    my $data = $self->data;
    my $content = join " ", map { $data->{$_} || '' } @soa_fields;
    return $content;
}

has '+data' => (
    isa     => 'HashRef',
    traits  => ['Hash'],
    handles => {
                map { ( $_ => [ accessor => $_ ] ) } @soa_fields
               }
);

1;
