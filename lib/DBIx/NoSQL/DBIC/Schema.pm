package DBIx::NoSQL::DBIC::Schema;

use strict;
use warnings;

use DBIx::Class::Schema;
use DBIx::NoSQL::Schema;

my $__serial__ = -1;
our $serial = sub {
    return $__serial__ += 1;
};

use Any::Moose;

has package => qw/ is ro lazy_build 1 /;
sub _build_package {
    return 'DBIx::NoSQL::__Anonymous__::Class' . $serial->();
}

has package_meta => qw/ is ro lazy_build 1 /;
sub _build_package_meta {
    my $self = shift;
    return any_moose( 'Meta::Class' )->create( $self->package );
}

sub build {
    my $self = shift;

    $self->package_meta->superclasses( 'DBIx::NoSQL::Schema' );
}

package DBIx::NoSQL::DBIC::ResultSource;

use strict;
use warnings;

use Any::Moose;

has package => qw/ is ro lazy_build 1 /;
sub _build_package {
    my $self = shift;
    return 'DBIx::NoSQL::__Anonymous__::Class' . $serial->();
}

has package_meta => qw/ is ro lazy_build 1 /;
sub _build_package_meta {
    my $self = shift;
    return any_moose( 'Meta::Class' )->create( $self->package );
}

sub build {
    my $self = shift;

    $self->extend( 'DBIx::Class::Core' );
}

sub extend {
    my $self = shift;
    my $target = shift;

    my $package = $self->package;
    eval "push \@${package}::ISA, '$target'";
}

1;
