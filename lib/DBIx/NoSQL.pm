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

use DBIx::NoSQL::Entitymodel;

has dbh => qw/ is ro lazy_build 1 /;
sub _build_dbh {
    my $self = shift;
    return $self->schema->storage->dbh;
}

has _model => qw/ is ro lazy_build 1 /;
sub _build__model { {} }

sub model {
    my $self = shift;
    my $name = shift or die "Missing model name";

    return $self->_model->{ $name } ||= DBIx::NoSQL::EntityModel->new( store => $self, name => $name );
}

sub prepare {
    my $self = shift;
    for my $name ( @_ ) {
        my $model = $self->model( $name );
        $model->prepare;
    }
}

sub search {
    my $self = shift;
    my $name = shift or die "Missing model name";

    my $model = $self->_model->{ $name } or die "No such model ($name)";
    return $model->search( @_ );
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

    $store_result_class->package->register( $schema_class->package, $store_result_class->package->table );
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
