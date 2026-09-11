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

    die "Please use image_from_uid, image_from_name or list_images";
}

# Every image matching %query, pagination followed.
#
# The warning above is about listing images *unfiltered*, which really can take
# fifty requests -- but there was no way to ask for a filtered list either, and
# some questions have no single-image answer.  "Which snapshots does this
# instance have" is one: Glance holds them as ordinary images, and the only way
# to find them is to ask for the ones matching.
#
# %query goes to Glance as request parameters, so the filtering happens there
# rather than here: name, owner, visibility, status, and any image property --
# Nova stamps its snapshots with image_type and instance_uuid, which is the
# narrow way to ask that question.
#
# Pagination is OpenStack::Client's; all() follows the 'next' link until there
# is not one.
sub list_images {
    my ($self, %query) = @_;

    return $self->client->all($self->root_uri('/images'), 'images', \%query);
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

__DATA__
---
keypairs:
  listable: 1
flavors:
  listable: 1



