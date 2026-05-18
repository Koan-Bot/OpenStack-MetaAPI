package OpenStack::MetaAPI::API::Images;

use strict;
use warnings;

use Moo;

extends 'OpenStack::MetaAPI::API::Service';

# roles
with 'OpenStack::MetaAPI::Roles::Listable';

has '+name'           => (default => 'image');
has '+version_prefix' => (default => 'v2');

=pod

Note loading all images can be very slow
as we have to use multiple requests (kind of pagination)...
and can result to require more than 50 requests...

For this reason we would prefer selecting one image
either by its 'exact name' or its 'UID'

=cut

sub images {
    my ($self, @args) = @_;

    die "Please use image_from_uid image_from_name";
}

# API doc
# https://developer.openstack.org/api-ref/image/v2/?expanded=list-images-detail

# FIXME: should be added to specs
sub image_from_uid {
    my ($self, $uid) = @_;

    die unless defined $uid;

    my $uri = $self->root_uri('/images/' . $uid);

    return $self->get($uri);
}

sub image_from_name {
    my ($self, $name) = @_;

    # v2/images?name=in:"glass,%20darkly"

    die unless defined $name;

    my $uri = $self->root_uri('/images');

    my $reply = $self->get($uri, name => qq{in:"$name"});

    return unless ref $reply && $reply->{images};

    my $images = $reply->{images};

    return unless ref $images;

    if (scalar @$images > 1) {
        warn
          "image_from_name: more than one image sharing the same name '$name'";
        return $images;
    }

    return $images->[0];
}

### helpers

1;
