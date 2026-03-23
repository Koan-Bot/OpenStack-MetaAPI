package OpenStack::MetaAPI::Roles::GetFromId;

use strict;
use warnings;

use Moo::Role;

sub _get_from_id_spec {
    my ($self, $route, $id) = @_;

    die "route must be defined when using get_from_id" unless defined $route;
    die "invalid route '$route' - must starts with /"  unless $route =~ m{^/};
    die "Undefined 'id' for route '$route'"            unless defined $id;

    $route .= '/' unless $route =~ m{/$};

    #my $uri = $self->root_uri( $route );

    my $answer = $self->get($route);

    if (ref $answer eq 'HASH' && scalar keys %$answer == 1) {
        my ($mainkey) = keys %$answer;
        return $answer->{$mainkey};
    }

    return $answer;
}

1;
