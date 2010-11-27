package DBIx::NoSQL::Model::Field;

use strict;
use warnings;

use Any::Moose;

has name => qw/ is ro required 1 /;

has index => qw/ is rw /;
has type => qw/ is rw /;

sub setup {
    my $self = shift;
    my $model = shift;

    my %given = @_;

    exists $given{ $_ } && $self->$_( $given{ $_ } ) for qw/ index /;
    if ( my $type_name = $given{ isa } ) {
        $self->type( $type_name );
        if ( my $type = $model->store->type_map->type( $type_name ) ) {
            $model->_field2inflate_map->{ $self->name } = $type->inflator;
            $model->_field2deflate_map->{ $self->name } = $type->deflator;
        }
    }

    return $self;
}

sub install_index {
    my $self = shift;
    my $model = shift;
    my $result_class = shift;

    my $column = $self->name;

    $model->_field2column_map->{ $self->name } = $column;

    $result_class->add_column( $column => {
        data_type => 'text',
        is_nullable => 1,
    } );
}

1;
