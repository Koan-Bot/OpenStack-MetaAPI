package OpenStack::MetaAPI::API::Network;

use strict;
use warnings;

use Moo;

extends 'OpenStack::MetaAPI::API::Service';

# roles
with 'OpenStack::MetaAPI::Roles::Listable';
with 'OpenStack::MetaAPI::Roles::GetFromId';

has '+name'           => (default => 'network');
has '+version_prefix' => (default => 'v2.0');
has '+version'        => (default => 'v2');        # use the v2 specs

# delete_floatingip is now generated from specs (type: remove)
# create_floating_ip is now generated from specs (type: create)

sub add_floating_ip_to_server {
    my ($self, $floatingip_id, $server_id) = @_;

    die "floatingip_id is required" unless defined $floatingip_id;
    die "server_id is required"     unless defined $server_id;

    my $uri = $self->root_uri('/ports');
    my $ports = $self->get($uri, device_id => $server_id);

    # pick the first port for now (maybe need to check the network_id...)
    my $port_id = eval { $ports->{ports}->[0]->{id} };
    die "Cannot find a port for server $server_id: $@" unless defined $port_id;

    # use the spec-generated update_floatingip method
    return $self->can_method('update_floatingip')
      ->($self, $floatingip_id, port_id => $port_id);
}

1;
