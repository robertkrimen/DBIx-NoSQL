package DBIx::NoSQL::EntitySearchSource;

use strict;
use warnings;

use Any::Moose;

has entity_source => qw/ is ro required 1 /;
has key_column => qw/ is rw isa Str lazy_build 1 /;
sub _build_key_column { 'key' }

has [qw/ create_statement drop_statement /] => qw/ is rw isa Maybe[Str] /;

sub register_search_class {
    my $self = shift;
    my $search_class = shift;

    my $store = $self->entity_source->store;
    my $schema = $store->schema;
    my $moniker = $self->entity_source->moniker;

    $schema->unregister_source( $moniker ) if $schema->source_registrations->{ $moniker };

    my $key_column = $self->key_column;
    unless( $search_class->has_column( $key_column ) ) {
        $search_class->add_column( $key_column => {
            data_type => 'text'
        } );
    }
    unless( $search_class->primary_columns ) {
        $search_class->set_primary_key( $key_column );
    }

    $schema->register_class( $moniker => $search_class );
    $self->entity_source->clear_search_source;

    my $table = $search_class->table;
    my $sql = $schema->generate_sql;
    my @sql = split m/;\n/, $sql;
    my ( $create ) = grep { m/(?:(?i)CREATE\s+TABLE\s+)$table/ } @sql;
    my ( $drop ) = grep { m/(?:(?i)DROP\s+TABLE\s+.*)$table/ } @sql;

    $self->create_statement( $create );
    $self->drop_statement( $drop );
}

sub deploy {
    my $self = shift;

    my $store = $self->entity_source->store;
    my $create = $self->create_statement;

    my ( $count ) = $store->dbh->selectrow_array(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?", undef, $self->entity_source->moniker );
    if ( ! $count ) {
        $store->dbh->do( $create );
    }
}

1;

__END__
    my $result_class = 'DBIx::Class::Row';
    my $key_column = $self->key_column;

    $schema->unregister_source( $moniker ) if $schema->source_registrations->{ $moniker };

    $table_source->add_column( $key_column => { data_type => 'text' } );

    $schema->register_class( $moniker => $table_source );
    $self->entity_source->clear_search_source;

    my $sql = $schema->generate_sql;
    my @sql = split m/;\n/, $sql;
    my ( $create ) = grep { m/(?:(?i)CREATE\s+TABLE\s+)+$moniker/ } @sql;
    my ( $drop ) = grep { m/(?:(?i)DROP\s+TABLE\s+.*)$moniker/ } @sql;

    $self->create_statement( $create );
    $self->drop_statement( $drop );
}

1;
