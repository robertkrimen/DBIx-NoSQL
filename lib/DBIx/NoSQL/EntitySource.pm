package DBIx::NoSQL::EntitySource;

use Modern::Perl;

use Any::Moose;

has store => qw/ is ro required 1 weak_ref 1 /;
has moniker => qw/ is ro required 1 /;

sub set {
    my $self = shift;
    my $data = shift;

    my $json = $self->store->json->encode( $data );
}

1;

__END__

has store => qw/ is ro required 1 weak_ref 1 /;

has table => qw/ is rw lazy_build 1 /;
sub _build_table { return $_[0]->moniker }

has key_column => qw/ is ro lazy_build 1 /;
sub _build_key_column { '__key__' }

has key_field => qw/ is ro lazy_build 1 /;
sub _build_key_field { 'key' }

has data_column => qw/ is ro lazy_build 1 /;
sub _build_data_column { '__data__' }

for my $operation (qw/ put set write find parse derive align merge insert update /) {
    no strict 'refs';
    my $dispatch = "${operation}_dispatch";
    my $original = "_${operation}";
    has $dispatch =>
        qw/ is ro lazy 1 /,
        default => sub {
            my $self = shift;
            DBIx::NoSQL::SubDispatch->new( original => $self->can( $original ) );
        },
    ; 
    *$operation = sub {
        return $_[0]->$dispatch unless @_ > 1;
        return $_[0]->$dispatch->run( @_ );
#        if ( $operation eq 'set' ) {
#            shift->_set_with_context( @_ );
#        }
#        else {
#            return $_[0]->$dispatch->run( @_ );
#        }
    }
}

#sub _set_with_context {
#    my $self = shift;
#    
#    my $context = {};
#    return $self->set_dispatch->run( $self, $context, @_ );
#}

sub _put {
    my $self = shift;
    my ( $key, $input );
    if ( @_ > 1 ) {
        $key = shift;
    }
    $input = shift;

    my $data = {};
    $data = $self->parse( $input );

    if ( defined $key ) {
        if ( my $entity = $self->find_by_key( $key ) ) {
            my $found_data = $entity->data;
            $data = $self->merge( $found_data, $data );
        }
    }

    return $self->set( $key => $data );
}

sub _parse {
    my $self = shift;
    my $row = shift;
    return $row;
}

sub _set {
    my $self = shift;
    my ( $key, $data );
    if ( @_ > 1 ) {
        $key = shift;
    }
    $data = shift;

    if ( defined $key ) {
        my $data_key = $data->{ $self->key_field };
        if ( defined $data_key ) {
            die "Key mismatch ($data_key) <> ($key)" unless $key eq $data_key;
        }
        else {
            $data->{ $self->key_field } = $key;
        }
    }

    $self->derive( $data );

    my $row = {};
    $self->align( $row, $data );

    $key =
    $row->{ $self->key_column } = $data->{ $self->key_field };
    $row->{ $self->data_column } = $self->store->json->encode( $data );

    $self->store->transact( sub { # TODO Move this to _write_first
        $self->write( $key => $row );
    } );

    my ( $statement, @bind ) = SQL::Abstract->new->select( $self->table, '*', { $self->key_column => $key } );
    my $result = $self->store->dbh->selectrow_hashref( $statement, undef, @bind );
    return $result;
}

# Merge with original
sub _merge {
    my $self = shift;
    my $old = shift;
    my $new = shift;
    return Hash::Merge::Simple::merge( $old, $new );
}

# Derive values from other values
sub _derive {
    my $self = shift;
    my $data = shift;
    return $data;
}

# Assign to table columns
sub _align {
    my $self = shift;
    my $data = shift;
    return {};
}

sub _write {
    my $self = shift;
    my ( $key, $row );
    if ( @_ > 1 ) {
        $key = shift;
    }
    $row = shift;

    if ( defined $key ) {
        my $row_key = $row->{ $self->key_column };
        if ( defined $row_key ) {
            die "Key mismatch ($row_key) <> ($key)" unless $key eq $row_key;
        }
        else {
            $row->{ $self->key_column } = $key;
        }
    }

    if ( $self->find_by_key( $key ) ) {
        $self->update( $key => $row );
    }
    else {
        $self->insert( $row );
    }
}

sub _insert {
    my $self = shift;
    my $row = shift;

    my ( $statement, @bind ) = SQL::Abstract->new->insert(
        $self->table, $row );

    $self->store->dbh->do( $statement, undef, @bind );
}

sub _update {
    my $self = shift;
    my $key = shift;
    my $row = shift;

    my ( $statement, @bind ) = SQL::Abstract->new->update(
        $self->table, $row, { $self->key_column => $key } );

    $self->store->dbh->do( $statement, undef, @bind );
}

sub find_by_key {
    my $self = shift;
    my $key = shift;

    my ( $statement, @bind ) = SQL::Abstract->new->select( $self->table, '*', { $self->key_column => $key } );
    return unless my $row = $self->store->dbh->selectrow_hashref( $statement, undef, @bind );
    return DBIx::NoSQL::Entity->new( source => $self, row => $row );
}

sub _find {
    my $self = shift;
}

package DBIx::NoSQL::ResultSource::key;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $key = shift;
    my $self = bless \$key, $class;
}

sub key { return ${ $_[0] } }

1;

__END__

#    $self->spectus->txn( sub {
#    } );

#sub set {
#    my $self = shift;
#    my ( $match, $row );
#    if ( 1 == @_ )  { $row = shift }
#    else            { ( $match, $row ) = ( shift, shift ) }

#    $row = $self->parse( $row );

#    if ( $match ) {
#        $match = $self->find( $match ) 
#            or die "Unable to find match ($match)";
#        $row = $self->merge( $match->data, $row );
#    }

#    $row = $self->derive( $row );

#    my $playlist = $row->{playlist};
#    $row = $self->align( $row );

#    $self->spectus->txn( sub {

#        if ( $match )   { $self->_update( $match, $row ) }
#        else            { $match = $self->_insert( $row ) }

#        my $part = 1;
#        for my $id ( @$playlist ) {
#            $self->spectus->match_video->search({ id => $id })->
#                update({ part => $part, match_id => $match->id });
#            $part += 1;
#        }

#        $match = $self->find({ id => $match->id });

#    } );

#    return $match;
#}

