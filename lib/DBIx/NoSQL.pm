package DBIx::NoSQL;
# ABSTRACT: Experimental NoSQL-ish overlay for an SQL database

use strict;
use warnings;

use Any::Moose;
use Try::Tiny;
use Path::Class;

use JSON;
eval { require JSON::XS; };
our $json = JSON->new->pretty;
sub json { $json }

use DBIx::NoSQL::EntitySource;

has dbh => qw/ is ro lazy_build 1 /;
sub _build_dbh {
    my $self = shift;
    return $self->schema->storage->dbh;
}

has _source => qw/ is ro lazy_build 1 /;
sub _build__source { {} }

sub source {
    my $self = shift;
    my $moniker = shift or die "Missing moniker";

    return $self->_source->{ $moniker } ||= DBIx::NoSQL::EntitySource->new(
        store => $self, moniker => $moniker );
}

sub prepare {
    my $self = shift;
    for my $name ( @_ ) {
        my $type = $self->source( $name );
        $type->prepare;
    }
}

sub search {
    my $self = shift;
    my $moniker = shift or die "Missing moniker";

    my $source = $self->_source->{ $moniker } or die "No such moniker ($moniker)";
    return $source->search( @_ );
}

has database => qw/ is ro required 1 /;

require DBIx::NoSQL::Class;

has schema_class => qw/ is ro lazy_build 1 /;
sub _build_schema_class {
    my $self = shift;
    return DBIx::NoSQL::Class->new->become_Schema;
}

has schema => qw/ reader _schema lazy_build 1 predicate _has_schema /;
sub _build_schema {
    my $self = shift;

    my $database = $self->database;
    my $schema_class = $self->schema_class;
    my $store_result_class = DBIx::NoSQL::Class->new->become_ResultClass_Store;

    $store_result_class->package->register( $schema_class->package, '__Entity__' );
    my $schema = $self->schema_class->package->connect( "dbi:SQLite:dbname=$database" );
    return $schema;
}

sub schema {
    my $self = shift;
    return $self->_schema if $self->_has_schema;
    my $database = file $self->database;
    my $exists = -s $database;
    my $schema = $self->_schema;
    unless ( $exists ) {
        $database->parent->mkpath;
        $schema->deploy;
    }
    return $schema;
}

sub transact {
    my $self = shift;
    my $code = shift;

    my $dbh = $self->dbh;
    try {
        $dbh->begin_work;
        $code->();
        $dbh->commit;
    }
    catch {
        try {
            $dbh->rollback;
        }
    }
}

1;
