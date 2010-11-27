package DBIx::NoSQL::Model;

use Modern::Perl;

use Any::Moose;
use Clone qw/ clone /;
use Digest::SHA qw/ sha1_hex /;

has store => qw/ is ro required 1 weak_ref 1 /, handles => [qw/ storage /];
has name => qw/ reader name writer _name required 1 /;

has indexable => qw/ is rw isa Bool default 1 /;

has inflate => qw/ accessor _inflate isa Maybe[CodeRef] /;
has deflate => qw/ accessor _deflate isa Maybe[CodeRef] /;
sub inflator { return shift->_inflate( @_ ) }
sub deflator { return shift->_deflate( @_ ) }

has wrap => qw/ accessor _wrap /;
sub wrapper { return shift->_wrap( @_ ) }

has field_map => qw/ is ro lazy_build 1 isa HashRef /;
sub _build_field_map { {} }
sub field {
    require DBIx::NoSQL::Model::Field;
    my $self = shift;
    my $name = shift;

    return $self->field_map->{ $name } unless @_;

    die "Already have field ($name)" if $self->field_map->{ $name };
    my $field = $self->field_map->{ $name } = DBIx::NoSQL::Model::Field->new( name => $name );
    $field->setup( $self, @_ );
    return $field;
}
has _field2column_map => qw/ is ro /, default => sub { {} };
has _field2inflate_map => qw/ is ro /, default => sub { {} };
has _field2deflate_map => qw/ is ro /, default => sub { {} };

sub _store_set {
    my $self = shift;
    return $self->store->schema->resultset( '__Store__' );
}

sub _index_set {
    my $self = shift;
    return $self->store->schema->resultset( $self->name );
}

sub _find {
    my $self = shift;
    my $key = shift;

    my $result = $self->_store_set->find(
        { __model__ => $self->name, __key__ => $key },
        { key => 'primary' },
    );

    return $result;
}

sub create {
    my $self = shift;
    return $self->create_object( @_ );
}

sub create_object {
    my $self = shift;
    my $target = shift;

    my $data = $self->deserialize( $target );
    my $entity = $self->inflate( $data );
    my $object = $self->wrap( $entity );

    return $object;
}

sub set {
    my $self = shift;
    my $key = shift;
    my $target = shift;

    my ( $entity, $data, $value );

    if ( blessed $target ) {
        $entity = $self->unwrap( $target );
        $target = $entity;
    }

    if ( ref $target ) {
        $data = $self->deflate( $target );
        $target = $data;
    }

    $value = $self->serialize( $target );

    $self->_store_set->update_or_create(
        { __model__ => $self->name, __key__ => $key, __value__ => $value },
        { key => 'primary' },
    );

    return unless $self->indexable;

    $self->_set_index( $key => $data );
}

sub _set_index {
    my $self = shift;
    my $key = shift;
    my $target = shift;

    my $data = $target;
    if ( $data && ! ref $data ) {
        $data = $self->deserialize( $target );
    }

    my %set;
    $set{ $self->key_column } = $key;
    while( my ( $field, $column ) = each %{ $self->_field2column_map } ) {
        $set{ $column } = $data->{ $field };
    }

    $self->store->schema->resultset( $self->name )->update_or_create(
        \%set, { key => 'primary' },
    );
}

sub exists {
    my $self = shift;
    my $key = shift;

    return $self->_store_set->search({ __key__ => $key })->count;
}

sub get {
    my $self = shift;
    my $key = shift;

    my $result = $self->_find( $key );

    return unless $result;

    return $self->create_object( $result->get_column( '__value__' ) );
}

sub delete {
    my $self = shift;
    my $key = shift;

    my $result = $self->_find( $key );
    if ( $result ) {
        $result->delete;
    }

    $result = $self->_search_set( 
        { $self->key_column => $key },
        { key => 'primary' }
    );
    if ( $result ) {
        $result->delete;
    }
}

sub wrap {
    my $self = shift;
    my $entity = shift;

    if ( my $wrapper = $self->wrapper ) {
        if ( ref $wrapper eq 'CODE' ) {
            return $wrapper->( $entity );
        }
        else {
            return $wrapper->new( _entity => $entity );
        }
    }

    return $entity;
}

sub unwrap {
    my $self = shift;
    my $target = shift;

    return $target->_entity if blessed $target;
    return $target;
}

sub inflate {
    my $self = shift;
    my $data = shift;

    my $entity = clone $data;
    
    while( my ( $field, $inflator ) = each %{ $self->_field2inflate_map } ) {
        $entity->{ $field } = $inflator->( $entity->{ $field } ) if defined $entity->{ $field };
    }

    return $entity;
}

sub deflate {
    my $self = shift;
    my $target = shift;

    my $data = {};

    while( my ( $field, $deflator ) = each %{ $self->_field2deflate_map } ) {
        $data->{ $field } = $deflator->( $target->{ $field } ) if defined $target->{ $field };
    }

    while( my ( $key, $value ) = each %$target ) {
        next if exists $data->{ $key };
        $data->{ $key } = ref $value ? clone $value : $value;
    }

    return $data;
}

sub deserialize {
    my $self = shift;
    my $value  = shift;

    return $value if ref $value;

    my $data = $self->store->json->decode( $value );
    return $data;
}

sub serialize {
    my $self = shift;
    my $data = shift;

    return $data if ! ref $data;

    my $value = $self->store->json->encode( $data );
    return $value;
}

sub search {
    my $self = shift;

    die "Trying to search on an unindexed model" unless $self->indexable;

    require DBIx::NoSQL::Search;
    my $search = DBIx::NoSQL::Search->new( model => $self );

    if ( @_ ) {
        $search->_where( $_[0] );
    }

    return $search;
}

has key_column => qw/ is rw isa Str lazy_build 1 /;
sub _build_key_column { 'key' }

has [qw/ create_statement drop_statement schema_digest /] => qw/ is rw isa Maybe[Str] /;

sub prepare {
    my $self = shift;

    return unless $self->indexable;

    $self->register_result_class;

    my $name = $self->name;
    my $stash_schema_digest = $self->store->stash->value( "mode.$name.index.schema_digest" );

    if ( ! $stash_schema_digest ) {
        $self->deploy;
    }
    else {
        my $schema_digest = $self->schema_digest;
        if ( $schema_digest ne $stash_schema_digest ) {
            $self->redeploy;
        }
    }
}

has result_class_scaffold => qw/ is ro lazy_build 1 /;
sub _build_result_class_scaffold { return DBIx::NoSQL::ClassScaffold->new->become_ResultClass }
has result_class => qw/ is ro lazy_build 1 /;
sub _build_result_class { return shift->result_class_scaffold->package }

sub register_result_class {
    my $self = shift;

    my $store = $self->store;
    my $schema = $store->schema;
    my $name = $self->name;
    my $result_class = $self->result_class;

    $schema->unregister_source( $name ) if $schema->source_registrations->{ $name };

    {
        unless ( $result_class->can( 'result_source_instance' ) ) {
            $result_class->table( $name );
        }

        my $key_column = $self->key_column;
        unless( $result_class->has_column( $key_column ) ) {
            $result_class->add_column( $key_column => {
                data_type => 'text'
            } );
        }
        unless( $result_class->primary_columns ) {
            $result_class->set_primary_key( $key_column );
        }

        for my $field ( values %{ $self->field_map } ) {
            next unless $field->index;
            unless( $result_class->has_column( $field->name ) ) {
                $field->install_index( $self, $result_class );
            }
        }
    }

    $schema->register_class( $name => $result_class );

    my $table = $result_class->table;
    my $deployment_statements = $schema->build_deployment_statements;
    my @deployment_statements = split m/;\n/, $deployment_statements;
    my ( $create ) = grep { m/(?:(?i)CREATE\s+TABLE\s+)$table/ } @deployment_statements;
    my ( $drop ) = grep { m/(?:(?i)DROP\s+TABLE\s+.*)$table/ } @deployment_statements;

    s/^\s*//, s/\s*$// for $create, $drop;

    $self->create_statement( $create );
    $self->drop_statement( $drop );
    $self->schema_digest( sha1_hex $create );
}

sub deploy {
    my $self = shift;

    my $store = $self->store;
    my $name = $self->name;

    my ( $count ) = $store->dbh->selectrow_array(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?", undef, $name );
    if ( ! $count ) {
        $self->store->stash->value( "mode.$name.index.schema_digest" => $self->schema_digest );
        $store->storage->do( $self->create_statement );
    }
}

sub redeploy {
    my $self = shift;

    my $store = $self->store;

    $store->storage->do( $self->drop_statement );
    $store->storage->do( $self->create_statement );

    my @result = $self->_store_set->search( { __model__ => $self->name } )->all;
    for my $result ( @result ) {
        $self->_set_index( $result->get_column( '__key__' ), $result->get_column( '__value__' ) );
    }
}

1;
