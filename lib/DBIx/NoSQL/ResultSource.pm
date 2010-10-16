package DBIx::NoSQL::ResultSource;

use Any::Moose;

use DBIx::NoSQL::SubDispatch;

has store => qw/ is ro required 1 weak_ref 1 /;

has moniker => qw/ is ro required 1 /;
has table => qw/ is rw lazy_build 1 /;
sub _build_table { return $_[0]->moniker }

has key_column => qw/ is ro lazy_build 1 /;
sub _build_key_column { '__key__' }

has key_field => qw/ is ro lazy_build 1 /;
sub _build_key_field { 'key' }

has value_column => qw/ is ro lazy_build 1 /;
sub _build_value_column { '__value__' }

for my $operation (qw/ set write find parse derive align merge insert update compose /) {
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
    }
}

sub _set {
    my $self = shift;
    my $search = shift;
    my $input = shift;

    my $value = {};
    my $data = {};
    $self->parse( $input );

    if ( $search ) {
        my $_value = $search->get;
        die "Invalid merge: data not found" unless $_value;
        $value = $self->merge( $_value, $value );
    }

    $self->derive( $value );

    $self->align( $data, $value );

    $self->compose( $value, $data );

    $self->write( $search, $data );
}

sub _parse {
    my $self = shift;
    my $data = shift;
    return $data;
}

# Merge with original
sub _merge {
}

# Derive values from other values
sub _derive {
    my $self = shift;
    my $value = shift;
    return $value;
}

# Assign to table columns
sub _align {
    my $self = shift;
    my $value = shift;
    return {};
}

# Set the key column, value column
sub _compose {
    my $self = shift;
    my $value = shift;
    my $data = shift;

    $data->{ $self->key_column } = $value->{ $self->key_field };
    $data->{ $self->value_column } = $self->store->json->encode( $value );

    return $data;
}

sub _find {
    my $self = shift;
}

sub _write {
    my $self = shift;
    my $search = shift;
    my $data = shift;

    $self->store->transact( sub {
        if ( $search ) {
            $self->update( $search, $data );
        }
        else {
            $self->insert( $data );
        }
    } );
}

sub _insert {
    my $self = shift;
    my $data = shift;

    my ( $statement, @bind ) = SQL::Abstract->new->insert(
        $self->table, $data );

    $self->store->dbh->do( $statement, undef, @bind );
}



1;


__END__

#    $self->spectus->txn( sub {
#    } );

#sub set {
#    my $self = shift;
#    my ( $match, $data );
#    if ( 1 == @_ )  { $data = shift }
#    else            { ( $match, $data ) = ( shift, shift ) }

#    $data = $self->parse( $data );

#    if ( $match ) {
#        $match = $self->find( $match ) 
#            or die "Unable to find match ($match)";
#        $data = $self->merge( $match->data, $data );
#    }

#    $data = $self->derive( $data );

#    my $playlist = $data->{playlist};
#    $data = $self->align( $data );

#    $self->spectus->txn( sub {

#        if ( $match )   { $self->_update( $match, $data ) }
#        else            { $match = $self->_insert( $data ) }

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

