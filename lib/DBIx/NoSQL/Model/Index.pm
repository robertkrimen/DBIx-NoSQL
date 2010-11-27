package DBIx::NoSQL::Model::Index;

use Modern::Perl;

use Any::Moose;
use Clone qw/ clone /;
use Digest::SHA qw/ sha1_hex /;

has model => qw/ is ro required 1 weak_ref 1 /, handles => [qw/ store storage /];

sub search {
    my $self = shift;

    require DBIx::NoSQL::Search;
    my $search = DBIx::NoSQL::Search->new( model => $self->model );

    if ( @_ ) {
        $search->_where( $_[0] );
    }

    return $search;
}

sub update {
    my $self = shift;
    my $key = shift;
    my $target = shift;

    my $model = $self->model;

    my $data = $target;
    if ( $data && ! ref $data ) {
        $data = $model->deserialize( $target );
    }

    my %set;
    $set{ $self->key_column } = $key;
    while( my ( $field, $column ) = each %{ $model->_field2column_map } ) {
        $set{ $column } = $data->{ $field };
    }

    $self->store->schema->resultset( $self->model->name )->update_or_create(
        \%set, { key => 'primary' },
    );
}

has key_column => qw/ is rw isa Str lazy_build 1 /;
sub _build_key_column { 'key' }

has [qw/ create_statement drop_statement schema_digest /] => qw/ is rw isa Maybe[Str] /;

sub prepare {
    my $self = shift;

    $self->register_result_class;

    my $name = $self->model->name;
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

    my $model = $self->model;
    my $store = $self->store;
    my $schema = $store->schema;
    my $name = $self->model->name;
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

        for my $field ( values %{ $model->field_map } ) {
            next unless $field->index;
            unless( $result_class->has_column( $field->name ) ) {
                $field->install_index( $model, $result_class );
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
    my $name = $self->model->name;

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

    my @result = $self->model->_store_set->search( { __model__ => $self->model->name } )->all;
    for my $result ( @result ) {
        $self->update( $result->get_column( '__key__' ), $result->get_column( '__value__' ) );
    }
}

1;
