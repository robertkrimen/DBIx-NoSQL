package DBIx::NoSQL::EntityModel::Field;

use Modern::Perl;

use Any::Moose;

has name => qw/ is ro required 1 /;

has index => qw/ is rw /;

sub setup {
    my $self = shift;
    my %given = @_;

    exists $given{ $_ } && $self->$_( $given{ $_ } ) for qw/ index /;

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
