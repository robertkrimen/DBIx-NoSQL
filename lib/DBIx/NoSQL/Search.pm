package DBIx::NoSQL::Search;

use Modern::Perl;

use Any::Moose;
use Hash::Merge::Simple qw/ merge /;

has entity_model => qw/ is ro required 1 /;

has [qw/ _where _order_by /] => qw/ is rw isa Maybe[HashRef] /;
has [qw/ _limit _offset /] => qw/ is rw /;

sub where {
    my $self = shift;
    my $where = shift;

    if ( my $_where = $self->_where ) {
        $where = merge $_where, $where;
    }

    return $self->clone( _where => $where ); 
}

sub clone {
    my $self = shift;
    my @override = @_;

    return ( ref $self )->new(
        entity_model => $self->entity_model,
        _where => $self->_where,
        _order_by => $self->_order_by,
        _limit => $self->_limit,
        _offset => $self->_offset,
    );
}

use DBIx::Class::SQLMaker;
sub prepare {
    my $self = shift;
    my $target = shift;

    my @where_order_limit_offset =
        $self->_where,
        $self->_order_by,
        $self->_limit,
        $self->_offset,
    ;

    my $maker = DBIx::Class::SQLMaker->new;

    my $entity_table = '__Store__';
    my $model_name = $self->entity_model->name;
    my $search_table = $model_name;
    my $search_key_column = 'key';

    if      ( $target eq 'value' )  { $target = '__Store__.__value__' }
    elsif   ( $target eq 'count' )  { $target = 'COUNT(*)' }
    else                            { die "Invalid target ($target)" }

    my ( $statement, @bind ) = $maker->select(
        [
            { me => $search_table },
            [
                { '-join-type' => 'LEFT', '__Store__' => $entity_table },
                { "__Store__.__key__" => "me.$search_key_column", '__Store__.__model__' => "'$model_name'" },
            ]
        ],
        $target,
        @where_order_limit_offset,
    );

    return ( $statement, @bind );
}

sub fetch {
    my $self = shift;

    my ( $statement, @bind ) = $self->prepare( 'value' );
    my $result = $self->entity_model->store->dbh->selectall_arrayref( $statement, undef, @bind );
    return map { $self->entity_model->deserialize( $_->[0] ) } @$result;
}

sub count {
    my $self = shift;

    my ( $statement, @bind ) = $self->prepare( 'count' );
    my $result = $self->entity_model->store->dbh->selectrow_arrayref( $statement, undef, @bind );
    return $result->[0];
}

1;
