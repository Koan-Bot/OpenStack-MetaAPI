package OpenStack::MetaAPI::API::Compute;

use strict;
use warnings;

use Moo;

# use Client::Lite::API role
#with 'OpenStack::MetaAPI::API'; ...

extends 'OpenStack::MetaAPI::API::Service';

# roles
#with    'OpenStack::MetaAPI::Roles::DataAsYaml';
with 'OpenStack::MetaAPI::Roles::Listable';
with 'OpenStack::MetaAPI::Roles::GetFromId';

has '+name' => (default => 'compute');

sub delete_server {
    my ($self, $uid) = @_;

    # first check that the server exists
    my $server = $self->api->server_from_uid($uid);
    return unless ref $server && $server->{id} eq $uid;

    my $api = $self->api;
    {
# delete floating ip for device [maybe provide its own helper at the main level of API]
        my $port_for_device = $api->ports(device_id => $uid);
        if ($port_for_device && $port_for_device->{id}) {

            my $port_id = $port_for_device->{id};
            my $floatingip = $api->floatingips(port_id => $port_id);

            if ($floatingip && $floatingip->{id}) {
                $api->delete_floatingip($floatingip->{id});
            }
        }
    }

    # maybe need to wait?
    my $uri = $self->root_uri('/servers/' . $uid);
    return $self->delete($uri);
}

# create_server is now generated from specs (type: create)

### helpers

1;
