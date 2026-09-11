# CLAUDE.md

Development guide for OpenStack-MetaAPI — a Perl 5 abstraction layer on top of OpenStack::Client.

## Project overview

This is a CPAN distribution (`OpenStack-MetaAPI`) that provides a unified API to interact with
multiple OpenStack services (Compute, Network, Images) through a single entry point. It uses
YAML-defined API specs to auto-generate methods for common operations (list, get-by-id), and
hardcodes more complex workflows (create_vm, delete_server).

**Status**: PRE-ALPHA. The module is functional but the API surface and specs are incomplete.

## Build and test

```bash
# Build (generates Makefile from dist.ini via Dist::Zilla, but Makefile.PL is committed)
perl Makefile.PL
make

# Run tests
make test

# Run a single test
prove -lv t/service-compute.t

# Author tests (extended)
prove -lv xt/
```

The build system is **Dist::Zilla** (`dist.ini`), but `Makefile.PL` is auto-generated and
committed for CI and non-dzil users.

## Architecture

### Entry point

`OpenStack::MetaAPI->new(...)` creates an auth object (`OpenStack::Client::Auth`) and a
`Routes` dispatcher. All API methods are delegated through `Routes` via Moo `handles`.

### Request flow

```
$api->servers(name => "web")
  → Routes::AUTOLOAD
    → Routes::service("compute")      # cached per-service
      → API::get_service(name => "compute")
        → require OpenStack::MetaAPI::API::Compute
        → Compute->new(auth => ..., region => ...)
          → BUILD: load specs for version (v2_1), call setup_api_methods_for_service()
    → service->can_method("servers")   # check Moo methods + dynamic methods hash
    → $code->($service, name => "web") # calls _list() from Listable role
```

### Key modules

| Module | Role |
|--------|------|
| `MetaAPI.pm` | Entry point, `create_vm`/`delete_server` workflows, `look_by_id_or_name` helper |
| `Routes.pm` | AUTOLOAD dispatcher, routes defined in `__DATA__` YAML block |
| `API.pm` | Factory: `get_service()` dynamically loads service classes |
| `API::Service.pm` | Base class for services (client, specs, version detection, method registry) |
| `API::Compute.pm` | Compute service: `delete_server`, `create_server` |
| `API::Network.pm` | Network service: floating IPs, ports |
| `API::Images.pm` | Image service: `image_from_uid`, `image_from_name` |
| `Roles::Listable` | `_list()` — client-side filtering with Regexp/eq support |
| `Roles::GetFromId` | `_get_from_id_spec()` — single resource retrieval by UID |
| `Helpers::DataAsYaml` | Loads YAML from `__DATA__` blocks with package-scoped caching |
| `API::Specs::Roles::Service` | Spec parser: reads YAML specs and generates methods via `setup_api_methods_for_service()` |

### Specs system

API methods are generated from YAML `__DATA__` blocks in spec files
(`Specs::Compute::v2_1`, `Specs::Network::v2`).

Supported spec types:
- **`listable`** — generates a method calling `_list()`. Requires `listable_key`.
- **`getfromid`** — generates a method calling `_get_from_id_spec()`. Requires `uid` placeholder.

Spec types NOT yet supported (methods must be hardcoded in service classes):
- POST (create operations)
- PUT (update operations)
- DELETE (remove operations)

Version detection: `Service::BUILD_version()` extracts version from the endpoint URL
(e.g., `/v2.1/...` → loads `Specs::Compute::v2_1`). Falls back to `Specs::Default` (empty).

### Routes

Routes map method names to services. Defined in `Routes.pm`'s `__DATA__` block:

```yaml
servers:
  service: compute
floatingips:
  service: network
image_from_uid:
  service: images
```

Adding a new route: add the entry to `__DATA__` in `Routes.pm` and ensure the service
class has a matching method (either spec-generated or hardcoded).

## Code conventions

- **Perl 5.14+** minimum (constrained by `OpenStack::Client` 1.0007 dependency)
- **Moo** for OO (not Moose) — `Moo::Role` for roles
- **YAML::XS** for YAML parsing (required dependency)
- Method naming: snake_case. Plural for list methods (`servers`, `flavors`), `_from_uid`/`_from_name` for lookups
- `root_uri()` handles version prefix prepending — routes starting with `/v` skip the prefix
- Client-side filtering in `_list()`: supports exact match (`eq`) and Regexp filters

## Testing patterns

Tests live in `t/`. They mock `LWP::UserAgent` and `HTTP::Request` to avoid network calls.

### Mock infrastructure

Tests use `Test::MockModule` to mock `LWP::UserAgent::request`:

```perl
my $mock_ua = Test::MockModule->new('LWP::UserAgent');
$mock_ua->redefine('request', sub { ... });
```

The mock returns `HTTP::Response` objects with JSON-encoded bodies.

Common test helper pattern (in `t/lib/Test/OpenStack/MetaAPI/Helpers.pm`):
- `mock_get_request()` — sets up mock responses
- Auth token mock — provides fake service catalog with endpoints

### Key testing gotchas

- **`_list()` return value**: Returns `undef` for 0 results, a hashref for 1 result,
  a list for 2+ results. In scalar context, a list becomes a count (integer), not the
  last element. Test accordingly.
- **`__DATA__` filehandle**: Consumed on first read. `clear_cache()` resets the in-memory
  cache but does NOT rewind the filehandle. Tests must load once and test from that state.
- **keypairs response**: Nested structure `{keypairs: [{keypair: {...}}, ...]}` — each
  entry is wrapped in a `keypair` key.

## CI

GitHub Actions workflow in `.github/workflows/ci.yml`:
- Matrix: Perl 5.14 through latest + devel
- Platforms: Linux (Docker containers), macOS, Windows
- Dependencies installed via `perl-actions/install-with-cpm` from `.github/cpanfile`

Failures on Perl < 5.14 are expected and acceptable (dependency constraint).

## Known limitations

- The `images()` list method is deliberately blocked (too slow due to pagination).
  Use `image_from_uid()` or `image_from_name()` instead.
- `_looks_valid_id()` is intentionally loose (accepts hex+hyphens) because OpenStack
  flavors use numeric IDs ("1", "2"), not UUIDs.
- `_get_from_id()` in `GetFromId.pm` is dead code — only `_get_from_id_spec()` is used
  by spec-generated methods.
- `Images.pm` has a stale `__DATA__` block with compute entries (keypairs, flavors) —
  it's dead code since Images doesn't use the `DataAsYaml` role directly.
- The `delete` section in Compute v2_1 specs generates a `getfromid`-type method
  (GET, not DELETE) — `delete_server` is hardcoded in `Compute.pm` instead.
