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
# delete floating ips for all ports on this device (supports multi-homed VMs)
        my @ports_for_device = $api->ports(device_id => $uid);
        for my $port (@ports_for_device) {
            next unless ref $port && $port->{id};

            my $floatingip = $api->floatingips(port_id => $port->{id});
            if ($floatingip && $floatingip->{id}) {
                $api->delete_floatingip($floatingip->{id});
            }
        }
    }

    # maybe need to wait?
    my $uri = $self->root_uri('/servers/' . $uid);
    return $self->delete($uri);
}

#  FIXME should be generated from specs
sub create_server {
    my ($self, %opts) = @_;

    my $uri = $self->root_uri('/servers/');
    my $output = $self->post($uri, {server => {%opts}});
    return $output->{server} if ref $output;
    return $output;
}

### helpers

1;
