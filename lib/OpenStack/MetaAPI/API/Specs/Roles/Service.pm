package OpenStack::MetaAPI::API::Specs::Roles::Service;

use strict;
use warnings;

use Moo::Role;

use OpenStack::MetaAPI::Helpers::DataAsYaml;

has 'specs' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $specs =
          OpenStack::MetaAPI::Helpers::DataAsYaml::LoadDataFrom(ref $self)
          // {};

        # populate missing keys
        $specs->{$_} //= {} for qw/get post put delete/;

        return $specs;
    });

sub get {
    my ($self, $route) = @_;

    $route = '/' . $route unless $route =~ m{^/};

    return $self->specs()->{get}->{$route};
}

sub post {
    my ($self, $route) = @_;

    $route = '/' . $route unless $route =~ m{^/};

    return $self->specs()->{post}->{$route};
}

sub put {
    my ($self, $route) = @_;

    $route = '/' . $route unless $route =~ m{^/};

    return $self->specs()->{put}->{$route};
}

sub delete {
    my ($self, $route) = @_;

    $route = '/' . $route unless $route =~ m{^/};

    return $self->specs()->{delete}->{$route};
}

sub query_filters_for {
    my ($self, $method, $route, $args) = @_;

    die unless defined $method;
    die unless defined $route;
    die unless ref $args eq 'ARRAY';

    return unless @$args % 2 == 0;

    my %filters = @$args;

    $method =~ s{^/+}{};

    my $spec = $self->can($method)->($self, $route);

    return
         unless ref $spec eq 'HASH'
      && ref $spec->{request}
      && ref $spec->{request}->{query};

    my %valid_filters = map { $_ => 1 } sort keys %{$spec->{request}->{query}};

    my $use_filters = {};

    foreach my $filter (sort keys %filters) {
        next unless defined $valid_filters{$filter};
        ### ... can use type & co ...
        $use_filters->{$filter} = $filters{$filter};
    }

    return unless scalar keys %$use_filters;
    return $use_filters;
}

## hook all methods to our object
sub setup_api_methods_for_service {
    my ($self, $service) = @_;

    my $specs = $self->specs;
    foreach my $method (sort keys %$specs) {
        foreach my $route (sort keys %{$specs->{$method}}) {
            my $rule = $specs->{$method}->{$route};
            next unless ref $rule && ref $rule->{perl_api};
            my $perl_api = $rule->{perl_api};

            my $code = sub { };

            my $from_txt =
              "from spec " . (ref $self->specs) . " for route $route";

            my $method_name = $perl_api->{method}
              or die "method is missing $from_txt";
            my $type = $perl_api->{type} or die "type is missing $from_txt";
            if ($type eq 'getfromid') {
                my $token = $perl_api->{uid} or die "uid is missing $from_txt";

                $code = sub {
                    my ($self, $uid) = @_;

                    my $r = $route;
                    $r =~ s[\Q$token\E][$uid]g;

                    return $self->_get_from_id_spec($r, $uid);
                };
            } elsif ($type eq 'listable') {
                my $listable_key = $perl_api->{listable_key}
                  or die "listable_key is missing $from_txt";
                $code = sub {
                    my ($self, @args) = @_;
                    return $self->_list([$route, $listable_key], \@args);
                };
            } elsif ($type eq 'create') {
                my $resource_key = $perl_api->{resource_key}
                  or die "resource_key is missing $from_txt";
                $code = sub {
                    my ($self, %opts) = @_;
                    my $uri = _resolve_uri($self, $route);
                    my $output =
                      $self->post($uri, {$resource_key => {%opts}});
                    return $output->{$resource_key}
                      if ref $output && $output->{$resource_key};
                    return $output;
                };
            } elsif ($type eq 'update') {
                my $token = $perl_api->{uid}
                  or die "uid is missing $from_txt";
                my $resource_key = $perl_api->{resource_key}
                  or die "resource_key is missing $from_txt";
                $code = sub {
                    my ($self, $uid, %opts) = @_;
                    my $r = $route;
                    $r =~ s[\Q$token\E][$uid]g;
                    my $uri = _resolve_uri($self, $r);
                    my $output =
                      $self->put($uri, {$resource_key => {%opts}});
                    return $output->{$resource_key}
                      if ref $output && $output->{$resource_key};
                    return $output;
                };
            } elsif ($type eq 'remove') {
                my $token = $perl_api->{uid}
                  or die "uid is missing $from_txt";
                $code = sub {
                    my ($self, $uid) = @_;
                    my $r = $route;
                    $r =~ s[\Q$token\E][$uid]g;
                    my $uri = _resolve_uri($self, $r);
                    return $self->delete($uri);
                };
            } else {
                die "Unknown type '$type' $from_txt";
            }

            $service->setup_method($method_name, $code);
        }
    }

    return;
}

# Resolve a spec route to a URI, applying root_uri only when the route
# does not already contain a version prefix (e.g. /v2.0/).
# This mirrors the convention used by _list() for listable routes.
sub _resolve_uri {
    my ($service, $uri) = @_;

    return $uri if $uri =~ m{^/v}i;
    return $service->root_uri($uri);
}

1;
