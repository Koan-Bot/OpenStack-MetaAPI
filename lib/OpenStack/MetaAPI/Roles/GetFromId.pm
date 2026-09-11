package OpenStack::MetaAPI::Roles::GetFromId;

use strict;
use warnings;

use Moo::Role;

# OpenStack hands ids back in two shapes and both have to round-trip: the
# dashed 8-4-4-4-12 form Nova and Glance use, and the undashed 32 hex digits
# Keystone uses for projects, users and tokens -- and which Nova's own server
# list is happy to return too.  Anything else (short strings, bare dashes,
# non-hex) is a caller mistake worth catching before it becomes a remote 404.
my $VALID_UUID = qr{^(?:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}|[a-f0-9]{32})$}i;

sub _get_from_id_spec {
    my ($self, $route, $id) = @_;

    die "route must be defined when using get_from_id" unless defined $route;
    die "invalid route '$route' - must starts with /"  unless $route =~ m{^/};
    die "Undefined 'id' for route '$route'"            unless defined $id;
    die
      "Invalid UUID format '$id' for route '$route' - expected 8-4-4-4-12 hex format or 32 hex digits"
      unless $id =~ $VALID_UUID;

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
