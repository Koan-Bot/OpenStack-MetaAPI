package OpenStack::MetaAPI::API::Specs::Network::v2;

use strict;
use warnings;

use Moo;

with 'OpenStack::MetaAPI::API::Specs::Roles::Service';

#
# API specs: incomplete need to be continued
# url:
#   https://developer.openstack.org/api-ref/network/v2/index.html?expanded=list-ports-detail#ports
#

1;

__DATA__
---
get:
  /v2.0/floatingips:
    perl_api:
      method: floatingips
      type: listable
      listable_key: floatingips
    request:
      query: {}
  /v2.0/networks:
    perl_api:
      method: networks
      type: listable
      listable_key: networks
    request:
      query: {}
  /v2.0/security-groups:
    perl_api:
      method: security_groups
      type: listable
      listable_key: security_groups
    request:
      query: {}
  /v2.0/ports:
    perl_api:
      method: ports
      type: listable
      listable_key: ports
    request:
      query:
        admin_state_up:
          type: boolean
        binding:host_id: {}
        description: {}
        device_id: {}
        device_owner: {}
        fixed_ips: {}
        id: {}
        ip_allocation: {}
        mac_address: {}
        name: {}
        network_id: {}
        prokect_id: {}
        revision_number: {}
        sort_dir: {}
        sort_key: {}
        status: {}
        tenant_id: {}
        tags: {}
        tags-any: {}
        not-tags: {}
        not-tags-any: {}
        fields: {}
        mac_learning_enabled:
          type: boolean
post:
  /v2.0/floatingips:
    perl_api:
      method: create_floating_ip
      type: create
      resource_key: floatingip
    request:
      body:
        floating_network_id:
          required: 1
        tenant_id: {}
        floating_ip_address: {}
        port_id: {}
        subnet_id: {}
        description: {}
put:
  /v2.0/floatingips/{floatingip_id}:
    perl_api:
      method: update_floatingip
      type: update
      uid: '{floatingip_id}'
      resource_key: floatingip
    request:
      path:
        floatingip_id:
          required: 1
      body:
        port_id: {}
        description: {}
  /v2.0/ports/{port_id}:
    perl_api:
      method: update_port
      type: update
      uid: '{port_id}'
      resource_key: port
    request:
      path:
        port_id:
          required: 1
      body:
        admin_state_up: {}
        allowed_address_pairs:
          type: array
        binding:host_id: {}
        binding:profile:
          type: object
        binding:vnic_type: {}
        data_plane_status: {}
        description: {}
        device_id: {}
        device_owner: {}
        dns_domain: {}
        dns_name: {}
        extra_dhcp_opts:
          type: array
delete:
  /v2.0/floatingips/{floatingip_id}:
    perl_api:
      method: delete_floatingip
      type: remove
      uid: '{floatingip_id}'
    request:
      path:
        floatingip_id:
          required: 1
