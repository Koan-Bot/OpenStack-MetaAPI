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

# ---------------------------------------------------------------------------
# Test 1: Nova-style pagination (servers_links with rel:next)
# ---------------------------------------------------------------------------
{
    note "Testing Nova-style pagination via servers_links";

    # Page 1: two servers + a next link
    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(<<'JSON'),
{
    "servers": [
        {"id": "aaa", "name": "server-1"},
        {"id": "bbb", "name": "server-2"}
    ],
    "servers_links": [
        {"rel": "next", "href": "http://127.0.0.1:8774/v2.1/servers?marker=bbb"}
    ]
}
JSON
    );

    # Page 2: one server, no next link
    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers?marker=bbb',
        application_json(<<'JSON'),
{
    "servers": [
        {"id": "ccc", "name": "server-3"}
    ]
}
JSON
    );

    my @servers = $api->servers();
    is scalar @servers, 3, "pagination collected all 3 servers across 2 pages";
    is [map { $_->{id} } @servers], [qw(aaa bbb ccc)],
      "servers returned in correct page order";
}

# ---------------------------------------------------------------------------
# Test 2: Single page (no pagination links) still works
# ---------------------------------------------------------------------------
{
    note "Testing single-page response (no pagination)";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(<<'JSON'),
{
    "servers": [
        {"id": "xxx", "name": "only-server"}
    ]
}
JSON
    );

    my $server = $api->servers();
    is $server->{id}, 'xxx', "single-page response returns one server";
}

# ---------------------------------------------------------------------------
# Test 3: servers_links present but no rel:next stops pagination
# ---------------------------------------------------------------------------
{
    note "Testing servers_links with only self (no next)";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(<<'JSON'),
{
    "servers": [
        {"id": "111", "name": "s1"},
        {"id": "222", "name": "s2"}
    ],
    "servers_links": [
        {"rel": "self", "href": "http://127.0.0.1:8774/v2.1/servers"}
    ]
}
JSON
    );

    my @servers = $api->servers();
    is scalar @servers, 2, "stops when no next link in servers_links";
}

# ---------------------------------------------------------------------------
# Test 4: Pagination with client-side filtering
# ---------------------------------------------------------------------------
{
    note "Testing pagination + client-side name filter";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(<<'JSON'),
{
    "servers": [
        {"id": "aaa", "name": "web-1"},
        {"id": "bbb", "name": "db-1"}
    ],
    "servers_links": [
        {"rel": "next", "href": "http://127.0.0.1:8774/v2.1/servers?marker=bbb"}
    ]
}
JSON
    );

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers?marker=bbb',
        application_json(<<'JSON'),
{
    "servers": [
        {"id": "ccc", "name": "web-2"}
    ]
}
JSON
    );

    my @servers = $api->servers(name => 'web-2');
    is scalar @servers, 1, "filter applied after full pagination";
    is $servers[0]->{id}, 'ccc', "correct server found on page 2";
}

# ---------------------------------------------------------------------------
# Test 5: Three pages of pagination
# ---------------------------------------------------------------------------
{
    note "Testing three pages of pagination";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(<<'JSON'),
{
    "servers": [
        {"id": "p1", "name": "page1"}
    ],
    "servers_links": [
        {"rel": "next", "href": "http://127.0.0.1:8774/v2.1/servers?marker=p1"}
    ]
}
JSON
    );

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers?marker=p1',
        application_json(<<'JSON'),
{
    "servers": [
        {"id": "p2", "name": "page2"}
    ],
    "servers_links": [
        {"rel": "next", "href": "http://127.0.0.1:8774/v2.1/servers?marker=p2"}
    ]
}
JSON
    );

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers?marker=p2',
        application_json(<<'JSON'),
{
    "servers": [
        {"id": "p3", "name": "page3"}
    ]
}
JSON
    );

    my @servers = $api->servers();
    is scalar @servers, 3, "three pages collected correctly";
    is [map { $_->{id} } @servers], [qw(p1 p2 p3)],
      "items from all three pages in order";
}

# ---------------------------------------------------------------------------
# Test 6: Network pagination (floatingips_links)
# ---------------------------------------------------------------------------
{
    note "Testing Neutron-style pagination via floatingips_links";

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/floatingips',
        application_json(<<'JSON'),
{
    "floatingips": [
        {"id": "fip-1", "floating_ip_address": "10.0.0.1"}
    ],
    "floatingips_links": [
        {"rel": "next", "href": "http://127.0.0.1:9696/v2.0/floatingips?marker=fip-1"}
    ]
}
JSON
    );

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/floatingips?marker=fip-1',
        application_json(<<'JSON'),
{
    "floatingips": [
        {"id": "fip-2", "floating_ip_address": "10.0.0.2"}
    ]
}
JSON
    );

    my @fips = $api->floatingips();
    is scalar @fips, 2, "Neutron pagination collected both floating IPs";
}

done_testing;
