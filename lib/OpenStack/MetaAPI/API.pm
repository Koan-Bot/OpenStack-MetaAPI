package OpenStack::MetaAPI::API;

use strict;
use warnings;

#use Moo::Role;
#use Moo;

sub get_service {
    my (%opts) = @_;

    my $name = $opts{name}      or die "name required";
    my $auth = ref($opts{auth}) or die "auth required";

    my $pkg = ucfirst $name;
    $pkg = __PACKAGE__ . "::$pkg";

    (my $file = $pkg) =~ s{::}{/}g;
    $file .= '.pm';
    eval { require $file; 1 } or die "Failed to load $pkg: $@";

    delete $opts{name};

    return $pkg->new(%opts);
}

1;
