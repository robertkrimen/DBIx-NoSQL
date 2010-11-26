package DBIx::NoSQL::Search;

use Modern::Perl;

use Any::Moose;
use Hash::Merge::Simple qw/ merge /;

has entity_model => qw/ is ro required 1 /, handles => [qw/ store storage /];

has [qw/ _where /] => qw/ is rw isa Maybe[HashRef] /;
has [qw/ _order_by /] => qw/ is rw isa Maybe[ArrayRef] /;
has [qw/ _limit _offset /] => qw/ is rw /;

has cursor => qw/ is ro lazy_build 1 /;
sub _build_cursor {
    my $self = shift;
    $self->_cursor( 'value' );
}

sub _cursor {
    my $self = shift;
    my $target = shift;
    my ( $statement, @bind ) = $self->prepare( $target );
    return $self->storage->cursor( $statement, \@bind );
}

sub where {
    my $self = shift;
    my $where = shift;

    if ( my $_where = $self->_where ) {
        $where = merge $_where, $where;
    }

    return $self->clone( _where => $where ); 
}

sub order_by {
    my $self = shift;
    my $order_by = shift;

    $order_by = [ $order_by ] unless ref $order_by;

    if ( my $_order_by = $self->_order_by ) {
        $order_by = [ @$_order_by, @$order_by ];
    }

    return $self->clone( _order_by => $order_by ); 
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
        @override
    );
}

use DBIx::Class::SQLMaker;
sub prepare {
    my $self = shift;
    my $target = shift;

    $target = 'value' unless defined $target;

    my %options;
    if ( my $order_by = $self->_order_by ) {
        $options{ order_by } = $order_by;
    }

    my @where_order_limit_offset = (
        $self->_where,
        \%options,
        $self->_limit,
        $self->_offset,
    );

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

sub get {
    my $self = shift;

    my $entity_model = $self->entity_model;
    my $all = $self->cursor->all;
    return map { $entity_model->create_object( $_->[0] ) } @$all;
}

sub fetch {
    my $self = shift;

    my $entity_model = $self->entity_model;
    my $all = $self->cursor->all;
    return map { $entity_model->deserialize( $_->[0] ) } @$all;
}

sub count {
    my $self = shift;

    my $cursor = $self->_cursor( 'count' );
    return unless my $result = $cursor->next;
    return $result->[0];
}

1;
