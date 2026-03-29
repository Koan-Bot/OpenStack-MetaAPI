#!/usr/bin/env perl

use strict;
use warnings;

use OpenStack::MetaAPI ();

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::OpenStack::MetaAPI qw{:all};
use Test::OpenStack::MetaAPI::Auth qw{:all};

use JSON;

mock_lwp_useragent();

my $api = get_api_object(use_env => 0);

ok $api, "got one api object" or die;

# ========================================================================
# Test: create type (POST with resource wrapping)
# ========================================================================
{
    note "Testing create_server via spec-generated create type";

    mock_post_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(<<'JSON'),
{
    "server": {
        "id": "aa-bb-cc-dd-ee",
        "name": "test-server",
        "status": "BUILD",
        "links": []
    }
}
JSON
    );

    my $result = $api->create_server(
        name      => 'test-server',
        imageRef  => '170fafa5-1329-44a3-9c27-9bb77b77206d',
        flavorRef => '1',
    );

    is last_http_request(),
      "POST http://127.0.0.1:8774/v2.1/servers",
      "create_server sends POST to correct URL";

    is $result,
      {
        id     => 'aa-bb-cc-dd-ee',
        name   => 'test-server',
        status => 'BUILD',
        links  => [],
      },
      "create_server unwraps the server resource from response";
}

# ========================================================================
# Test: create type for Network (with version prefix in route)
# ========================================================================
{
    note "Testing create_floating_ip via spec-generated create type";

    mock_post_request(
        'http://127.0.0.1:9696/v2.0/floatingips',
        application_json(<<'JSON'),
{
    "floatingip": {
        "id": "ff-00-ff-11-77",
        "floating_ip_address": "192.168.1.100",
        "floating_network_id": "net-123",
        "status": "ACTIVE"
    }
}
JSON
    );

    my $result = $api->create_floating_ip(
        floating_network_id => 'net-123',
    );

    is last_http_request(),
      "POST http://127.0.0.1:9696/v2.0/floatingips",
      "create_floating_ip sends POST to correct URL (no double v2.0)";

    is $result,
      {
        id                  => 'ff-00-ff-11-77',
        floating_ip_address => '192.168.1.100',
        floating_network_id => 'net-123',
        status              => 'ACTIVE',
      },
      "create_floating_ip unwraps the floatingip resource";
}

# ========================================================================
# Test: update type (PUT with UID substitution and resource wrapping)
# ========================================================================
{
    note "Testing update_floatingip via spec-generated update type";

    mock_put_request(
        'http://127.0.0.1:9696/v2.0/floatingips/ff-00-ff-11-77',
        application_json(<<'JSON'),
{
    "floatingip": {
        "id": "ff-00-ff-11-77",
        "port_id": "port-aaa-bbb",
        "floating_ip_address": "192.168.1.100",
        "status": "ACTIVE"
    }
}
JSON
    );

    my $result = $api->update_floatingip(
        'ff-00-ff-11-77',
        port_id => 'port-aaa-bbb',
    );

    is last_http_request(),
      "PUT http://127.0.0.1:9696/v2.0/floatingips/ff-00-ff-11-77",
      "update_floatingip sends PUT to correct URL with UID substituted";

    is $result,
      {
        id                  => 'ff-00-ff-11-77',
        port_id             => 'port-aaa-bbb',
        floating_ip_address => '192.168.1.100',
        status              => 'ACTIVE',
      },
      "update_floatingip unwraps the floatingip resource";
}

# ========================================================================
# Test: update type for ports
# ========================================================================
{
    note "Testing update_port via spec-generated update type";

    mock_put_request(
        'http://127.0.0.1:9696/v2.0/ports/port-111-222',
        application_json(<<'JSON'),
{
    "port": {
        "id": "port-111-222",
        "name": "updated-port",
        "admin_state_up": true,
        "status": "ACTIVE"
    }
}
JSON
    );

    my $result = $api->update_port(
        'port-111-222',
        name           => 'updated-port',
        admin_state_up => JSON::true,
    );

    is last_http_request(),
      "PUT http://127.0.0.1:9696/v2.0/ports/port-111-222",
      "update_port sends PUT to correct URL";

    is $result,
      {
        id             => 'port-111-222',
        name           => 'updated-port',
        admin_state_up => JSON::true,
        status         => 'ACTIVE',
      },
      "update_port unwraps the port resource";
}

# ========================================================================
# Test: remove type (DELETE with UID substitution)
# ========================================================================
{
    note "Testing delete_floatingip via spec-generated remove type";

    mock_delete_request(
        'http://127.0.0.1:9696/v2.0/floatingips/ff-00-ff-11-77',
        application_json(''),
    );

    $api->delete_floatingip('ff-00-ff-11-77');

    is last_http_request(),
      "DELETE http://127.0.0.1:9696/v2.0/floatingips/ff-00-ff-11-77",
      "delete_floatingip sends DELETE to correct URL (no double v2.0)";
}

# ========================================================================
# Test: remove type for Compute (delete_server_from_uid)
# ========================================================================
{
    note "Testing delete_server_from_uid via spec-generated remove type";

    mock_delete_request(
        'http://127.0.0.1:8774/v2.1/servers/aa-bb-cc-dd-ee',
        application_json(''),
    );

    $api->delete_server_from_uid('aa-bb-cc-dd-ee');

    is last_http_request(),
      "DELETE http://127.0.0.1:8774/v2.1/servers/aa-bb-cc-dd-ee",
      "delete_server_from_uid sends DELETE to correct URL";
}

done_testing;
