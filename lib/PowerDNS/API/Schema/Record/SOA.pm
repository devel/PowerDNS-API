package PowerDNS::API::Schema::Record::SOA;
use Moose;
extends 'PowerDNS::API::Schema::Record';

my @soa_fields = qw(primary hostmaster serial refresh retry expire default_ttl);
my %defaults = (
    primary     => 'ns',
    hostmaster  => 'hostmaster',
    serial      => 1,
    refresh     => 10800,
    retry       => 3600,
    expire      => 604800,
    default_ttl => 3600
);

sub fields {
    return @soa_fields;
}

sub _build_data {
    my $self = shift;

    # make new objects return the defaults;
    my %data = %defaults;

    if ($self->content) {
        @data{@soa_fields} = split /\s+/, $self->content;
    }
    return \%data;
}

sub format_content {
    my $self = shift;
    my $data = $self->data;
    my $content = join " ", map { $data->{$_} || $defaults{$_} } @soa_fields;
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

__END__

    if (my $mbox = config->{"pdns-soa"}->{hostmaster}) {
        params->{hostmaster} ||= $mbox;
    }
    use Data::Dump 'pp';
    my $p = params;
    pp($p);
