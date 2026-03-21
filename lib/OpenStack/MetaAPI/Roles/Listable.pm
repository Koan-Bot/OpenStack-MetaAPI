package OpenStack::MetaAPI::Roles::Listable;

use strict;
use warnings;

use Moo::Role;

sub _list {
    my ($self, $all_args, $caller_args) = @_;

  # all_args are arguments from the internal OpenStack::MetaAPI::API
  # caller_args are coming from the user to filter the results
  #   if some filters are also arguments to the request
  #   then appending them to the query will shorten the output and run it faster

    my @all;
    {
        my ($uri, @extra) = @$all_args;
        $uri = $self->root_uri($uri)
          if $uri !~ m{^/v};    # can be removed once dynmaic methods are used

        my $extra_filters =
          $self->api_specs()->query_filters_for('/get', $uri, $caller_args);

        my $attribute = $extra[0];
        my $opts = {};
        if ($extra_filters) {
            if (scalar @extra == 1) {
                $opts = {};
            } elsif (scalar @extra > 1) {
                die "Too many args when calling _list for all...";
            }
            $opts = {%$opts, %$extra_filters};
        } elsif (scalar @extra > 1) {
            $opts = $extra[-1] // {};
        }

        my $path = $uri;
        while (defined $path) {
            my $result = $self->client->get($path, %$opts);

            unless (defined $result->{$attribute}) {
                my $keys = join(', ', sort keys %$result);
                die "Response from $path does not contain attribute "
                  . "'$attribute', possible options are $keys";
            }

            push @all, @{$result->{$attribute}};

            $path = _extract_next_link($result, $attribute, $self->client->endpoint);

            # only pass query opts on the first request; subsequent pages
            # carry their own query string in the next link URL
            $opts = {};
        }
    }

    my @args = @$caller_args;

    # apply our filters to the raw results
    my $nargs = scalar @args;
    if ($nargs && $nargs % 2 == 0) {
        my %opts = @args;
        foreach my $filter (sort keys %opts) {
            my @keep;
            my $filter_isa = ref $opts{$filter} // '';
            foreach my $candidate (@all) {
                next unless ref $candidate;
                if ($filter_isa eq 'Regexp') {

                    # can use a regexp as a filter
                    next
                      unless $candidate->{$filter}
                      && $candidate->{$filter} =~ $opts{$filter};
                } else {

                    # otherwise do one 'eq' check
                    next
                      unless $candidate->{$filter}
                      && $candidate->{$filter} eq $opts{$filter};
                }

                push @keep, $candidate;
            }

            @all = @keep;

        }
    }

    # avoid to return a list when possible
    return $all[0] if scalar @all <= 1;

    # return a list
    return @all;
}

# Extract the next page URL from an OpenStack paginated response.
# Supports three pagination styles:
#   1. <attribute>_links: [ {rel:"next", href:"..."} ]  (Nova, Neutron)
#   2. links: { next: "..." }                           (Keystone)
#   3. next: "..."                                      (Glance)
sub _extract_next_link {
    my ($result, $attribute, $endpoint) = @_;

    my $raw;

    # Style 1: <attribute>_links array (e.g. servers_links, networks_links)
    my $links_key = "${attribute}_links";
    if (ref $result->{$links_key} eq 'ARRAY') {
        for my $link (@{$result->{$links_key}}) {
            if (ref $link eq 'HASH' && ($link->{rel} // '') eq 'next') {
                $raw = $link->{href};
                last;
            }
        }
        return unless defined $raw;
    }

    # Style 2: links hash with next key (Keystone)
    if (!defined $raw && ref $result->{links} eq 'HASH' && defined $result->{links}{next}) {
        $raw = $result->{links}{next};
    }

    # Style 3: top-level next key (Glance)
    $raw //= $result->{next};

    return unless defined $raw;

    # Normalize: strip the endpoint prefix from absolute URLs so the client
    # doesn't double-prepend it (client->get() always prepends the endpoint)
    if (defined $endpoint && $raw =~ m{^https?://}) {
        # strip trailing slash from endpoint for matching
        (my $base = $endpoint) =~ s{/+$}{};
        if ($raw =~ s{^\Q$base\E}{}) {
            # $raw is now a relative path like /servers?marker=...
        }
    }

    return $raw;
}

1;
