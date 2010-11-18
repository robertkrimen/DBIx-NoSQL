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

has type_map => qw/ is ro lazy_build 1 /;
sub _build_type_map { 
    my $self = shift;
    require DBIx::NoSQL::TypeMap;
    return DBIx::NoSQL::TypeMap->new();
}

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

require DBIx::NoSQL::ClassScaffold;

has schema_class_scaffold => qw/ is ro lazy_build 1 /;
sub _build_schema_class_scaffold { return DBIx::NoSQL::ClassScaffold->new->become_Schema }
has schema_class => qw/ is ro lazy_build 1 /;
sub _build_schema_class { return shift->schema_class_scaffold->package }

has schema => qw/ reader _schema lazy_build 1 predicate _has_schema /;
sub _build_schema {
    my $self = shift;

    my $database = $self->database;
    my $schema_class = $self->schema_class;
    my $store_result_class_scaffold = DBIx::NoSQL::ClassScaffold->new->become_ResultClass_Store;
    my $store_result_class = $store_result_class_scaffold->package;

    $store_result_class->register( $schema_class, $store_result_class->table );
    my $schema = $self->schema_class->connect( "dbi:SQLite:dbname=$database" );
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
