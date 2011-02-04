package Dancer::Serializer::JSONC;
use strict;
use base 'Dancer::Serializer::JSON';

sub serialize {
    my ($self, $entity, $options) = @_;
    $options ||= {};
    $options->{convert_blessed} = 1 unless defined $options->{convert_blessed};
    return $self->SUPER::serialize($entity, $options);
}

1;
