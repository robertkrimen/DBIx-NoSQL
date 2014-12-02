package FutonDb::ResultSet;

use Moose;

use SQL::Abstract;
use Hash::Merge::Simple qw/ merge /;

has source => qw/ is ro required 1 /;

has _where => qw/ is rw lazy_build 1 /;
sub _build__where { {} }

has _order_by => qw/ is rw lazy_build 1 /;
sub _build__order_by { {} }

sub search {
    my $self = shift;
    my $where = shift || {};

    if ( %$where ) {
        $self->_where( merge $self->_where, $where );
    }

    return $self;
}

sub select {
    my $self = shift;
    my @fieldlist = @_;

    return SQL::Abstract->new->select(
        $self->source->table, \@fieldlist, $self->_where, $self->_order_by );
}

sub value {
    my $self = shift;
    return $self->select( $self->source->value_column );
}


1;
