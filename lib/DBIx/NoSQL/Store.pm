package DBIx::NoSQL::Store;

use strict;
use warnings;

use Any::Moose;
use Try::Tiny;
use Path::Class;

use JSON;
eval { require JSON::XS; };
our $json = JSON->new->pretty;
sub json { $json }

use DBIx::NoSQL::Model;

has database => qw/ is ro /;
has connection => qw/ is ro /;

has storage => qw/ is ro lazy_build 1 /;
sub _build_storage {
    my $self = shift;
    require DBIx::NoSQL::Storage;
    return DBIx::NoSQL::Storage->new( store => $self );
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
    die "Missing model name" unless @_;
    if ( @_ > 1 ) {
        $self->model( $_ ) for @_;
    }
    else {
        my $name = shift or die "Missing model name";

        return $self->_model->{ $name } ||= DBIx::NoSQL::Model->new( store => $self, name => $name );
    }
}

sub validate {
    my $self = shift;
    my %options = @_;

    exists $options{ $_ } or $options{ $_ } = 1 for qw/ fatal /;

    my $valid = 1;
    for my $model ( values %{ $self->_model } ) {
        next unless my $indexer = $model->index;
        next unless $indexer->exists;
        $valid = $indexer->same;
        if ( ! $valid && $options{ fatal } ) {
            my $name = $model->name;
            die "Model \"$model\" has invalid indexer (indexer schema mismatch)";
        }
    }
}

sub migrate {
    my $self = shift;

    for my $model ( values %{ $self->_model } ) {
        next unless my $indexer = $model->index;
        $indexer->reset;
        next unless $indexer->exists;
        next if $indexer->same;
        $indexer->migrate;
    }
}

sub search {
    my $self = shift;
    my $name = shift or die "Missing model name";

    my $model = $self->_model->{ $name } or die "No such model ($name)";
    return $model->search( @_ );
}

has stash => qw/ is ro lazy_build 1 /;
sub _build_stash {
    require DBIx::NoSQL::Stash;
    my $self = shift;
    my $stash = DBIx::NoSQL::Stash->new( store => $self );
    $stash->model->prepare;
    return $stash;
}

require DBIx::NoSQL::ClassScaffold;

has schema_class_scaffold => qw/ is ro lazy_build 1 /;
sub _build_schema_class_scaffold { return DBIx::NoSQL::ClassScaffold->new->become_Schema }
has schema_class => qw/ is ro lazy_build 1 /;
sub _build_schema_class {
    my $self = shift;
    my $class = $self->schema_class_scaffold->package;

    my $store_result_class_scaffold = DBIx::NoSQL::ClassScaffold->new->become_ResultClass_Store;
    my $store_result_class = $store_result_class_scaffold->package;
    $store_result_class->register( $class, $store_result_class->table );

    return $class;
}

has schema => qw/ accessor _schema lazy_build 1 predicate _has_schema /;
sub _build_schema {
    my $self = shift;

    my $connection = $self->connection;
    if ( ! $connection ) {
        my $database = $self->database;
        if ( ! $database ) {
            die "Unable to connect schema to database because no connection or database are defined";
        }
        $connection = "dbi:SQLite:dbname=$database";
    }
    $connection = [ $connection ] unless ref $connection eq 'ARRAY';

    my $schema = $self->schema_class->connect( @$connection );
    $schema->store( $self );
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

has dbh => qw/ is ro lazy_build 1 weak_ref 1 /;
sub _build_dbh {
    my $self = shift;
    return $self->schema->storage->dbh;
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
