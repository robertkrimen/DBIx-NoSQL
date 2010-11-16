package DBIx::NoSQL::Class;

use strict;
use warnings;

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

sub push_ISA {
    my $self = shift;
    my $target = shift;

    my $package = $self->package;
    eval "push \@${package}::ISA, '$target'";
    return $self;
}

sub become_Schema {
    my $self = shift;

    require DBIx::Class::Schema;
    $self->package_meta->superclasses( 'DBIx::NoSQL::Class::Schema' );
    return $self;
}

sub become_ResultClass {
    my $self = shift;

    require DBIx::Class::Core;
    $self->push_ISA( 'DBIx::NoSQL::Class::ResultClass' );
    return $self;
}

sub become_ResultClass_Store {
    my $self = shift;

    $self->become_ResultClass;
    my $package = $self->package;

    $package->table( '__Entity__' );
    $package->add_columns(
        __moniker__ => {
            data_type => 'text',
        },
        __key__ => {
            data_type => 'text',
        },
        __value__ => {
            data_type => 'text',
            default_value => '{}',
        },
    );
    $package->set_primary_key(qw/ __moniker__ __key__ /);
    return $self;
}

package DBIx::NoSQL::Class::Schema;

use Any::Moose;

extends qw/ DBIx::Class::Schema /;

use JSON; our $json = JSON->new->pretty;
use Digest::SHA qw/ sha1_hex /;

has sql => qw/ is ro lazy_build 1 /;
sub _build_sql {
    return shift->generate_sql;
}

sub generate_sql {
    my $self = shift;
    my $sql = $self->deployment_statements( undef, undef, undef, { add_drop_table => 1 } );
    $sql =~ s/^--[^\n]*$//gsm;
    return $sql;
}

has version => qw/ is ro lazy_build 1 /;
sub _build_version {
    my $self = shift;
    return sha1_hex( $self->sql );
}

sub deploy {
    my $self = shift;
    my $sql = $self->sql;
    my @sql = split m/;\n/, $sql;
    warn join "\n", @sql, '';
    my $dbh = $self->storage->dbh;
    $dbh->do( $_ ) for @sql;
    #$self->jourpl->database->query(
        #'INSERT INTO __meta__ (version) VALUES (?)',
        #$self->version,
    #);
}

package DBIx::NoSQL::Class::ResultClass;

use strict;
use warnings;

use base qw/ DBIx::Class::Core /;

sub register {
    my $class = shift;
    my $schema_class = shift;
    my $moniker = shift;

    $schema_class->register_class( $moniker => $class );
}

1;

