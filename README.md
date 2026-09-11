# NAME

OpenStack::MetaAPI - Perl5 OpenStack API abstraction on top of OpenStack::Client

# VERSION

version 0.004

# SYNOPSIS

```perl
#!/usr/bin/env perl

use strict;
use warnings;

use OpenStack::MetaAPI ();

use Test::More;

SKIP: {
    skip "OS_AUTH_URL unset, please source one openrc.sh file before."
      unless $ENV{OS_AUTH_URL} && $ENV{AUTHOR_TESTING};

    # create one OpenStack::MetaAPI object
    #  this is using OpenStack::Client::Auth
    my $api = OpenStack::MetaAPI->new(
        $ENV{OS_AUTH_URL},
        username => $ENV{'OS_USERNAME'},
        password => $ENV{'OS_PASSWORD'},
        version  => 3,
        scope    => {
            project => {
                name   => $ENV{'OS_PROJECT_NAME'},
                domain => {id => 'default'},
            }
        },
    );

   # OpenStack API documentation:
   #   https://developer.openstack.org/api-guide/quick-start/#current-api-versions

    #
    # You can call most routes direclty on the main API object
    #   without the need to know which service is providing it
    #

    # list all flavors
    my @flavors      = $api->flavors();
    my $small        = $api->flavors(name => 'small');
    my @some_flavors = $api->flavors(name => qr{^(?:small|medium)});

    # list all servers
    my @servers = $api->servers();

    # filter the server result using any keys
    # Note: known API valid request arguments are used as part of the request
    @servers = $api->servers(name => 'foo');

    # can also use a regex
    @servers = $api->servers(name => qr{^foo});

    # get a single server by one id
    my $SERVER_ID = q[aaaa-bbbb-cccc-dddd];
    my $server    = $api->server_from_uid($SERVER_ID);

    # delete a server [also delete associated floating IPs]
    $api->delete_server($SERVER_ID);

    # listing floating IPs
    my @floatingips = $api->floatingips();

    # listing all images is currently not supported
    #  [slow as multiple requests are require 'next']
    # prefer selecting one image using one of these two helpers
    my $IMAGE_UID  = '1111-2222-3456';
    my $image      = $api->image_from_uid($IMAGE_UID);
    my $IMAGE_NAME = 'MyCustomImage';
    $image = $api->image_from_name($IMAGE_NAME);

    my @security_groups = $api->security_groups();

    my $SECURITY_GROUP_ID = '12345';

    my $security_group = $api->security_groups(id => $SECURITY_GROUP_ID);
    $security_group = $api->security_groups(name => 'default');

    # you can also create one server using the create_vm helper

    my $vm = $api->create_vm(
        name     => 'SERVER_NAME',
        image    => 'IMAGE_UID or IMAGE_NAME',    # image used to create the VM
        flavor   => 'small',
        key_name => 'your ssh key name',          # optional key to set
        security_group =>
          'default',    # security group to use, by default use 'default'
        network => 'NETWORK_NAME or NETWORK_ID',    # network group to use
        network_for_floating_ip => 'NETWORK_NAME or NETWORK_ID',
    );

}

1;
```

# DESCRIPTION

OpenStack::MetaAPI

Using OpenStack::MetaAPI you can call routes from any service directly on the main object.
Helpers are defined from the [specs](https://docs.openstack.org/api-quick-start/#current-api-versions) defined.

Currently only a very small part of the specs have been imported to this project.

This software is currently in `PRE-ALPHA` stage... use it at your own risk!
Feel free to report issues to the Bug Tracker or contribute.

# Available functions / methods

## new( \[ Arguments for OpenStack::Client::Auth \] )

Create one OpenStack::MetaAPI object.
For now all arguments passed to `new` are used to create one [OpenStack::Client::Auth](https://metacpan.org/pod/OpenStack%3A%3AClient%3A%3AAuth).

## $api->flavors( \[ %filter \] )

List all flavors from the compute service. \[view synopsis for some sample usage\]

## $api->servers( \[ %filter \] )

List all servers from the compute service. \[view synopsis for some sample usage\]

## $api->floatingips( \[ %filter \] )

List all floatingips from the network service. \[view synopsis for some sample usage\]

## $api->security\_groups( \[ %filter \] )

List all security\_groups from the network service. \[view synopsis for some sample usage\]

## $api->image\_from\_uid( $image\_uid )

Select one image from its UID. \[view synopsis for some sample usage\]

## $api->image\_from\_name( $image\_name )

Select one image from its name. \[view synopsis for some sample usage\]

## $api->create\_vm( %args )

Create one server from one image with one floating IP, wait for the server to be ready.

```perl
    my $vm = $api->create_vm(
        name     => 'SERVER_NAME',
        image    => 'IMAGE_UID or IMAGE_NAME',   # image used to create the VM
        flavor   => 'small',
        key_name => 'your ssh key name',         # optional key to set
        security_group => 'default',    # security group to use, by default use 'default'
        network => 'NETWORK_NAME or NETWORK_ID',    # network group to use
        network_for_floating_ip => 'NETWORK_NAME or NETWORK_ID',
    );
```

## $api->delete\_server( $server\_id );

Delete a server from its id. Note floating IP linked to the server are also deleted.

# SEE ALSO

This module is a wrapper around [OpenStack::Client](https://metacpan.org/pod/OpenStack%3A%3AClient) and [OpenStack::Client::Auth](https://metacpan.org/pod/OpenStack%3A%3AClient%3A%3AAuth)

- [OpenStack::Client](https://metacpan.org/pod/OpenStack%3A%3AClient) - OpenStack API client.

# TODO

- refactor/clean existing prototype
- increase API Specs defintion
- plug methods to route from API Specs
- helper to purge unused floatingips
- helper to purge unused servers
- increase POD & add some extra examples
- POD for using filtering: using RegExp, ...
- improve filtering on the request when described by the specs

# LICENSE

This software is copyright (c) 2019 by cPanel, L.L.C.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming
language system itself.

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY
APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE
OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY
WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS
BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

# AUTHOR

Nicolas R <atoomic@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
