package DBIx::NoSQL;
# ABSTRACT: Experimental NoSQL-ish overlay for an SQL database

use strict;
use warnings;

use DBIx::NoSQL::Store;

sub new {
    my $class  = shift;
    return DBIx::NoSQL::Store->new( @_ );
}

1;

    #for $artist ( $store->search( 'Artist' )->order_by( 'genre' ) ) {
    #    ...
    #}

__END__

=head1 SYNOPSIS

    use DBIx::NoSQL;

    my $store = DBIx::NoSQL->new;

    $store->connect( 'store.sqlite' );

    $store->set( 'Artist' => 'Smashing Pumpkins' => {
        name => 'Smashing Pumpkins',
        genre => 'rock',
        website => 'smashingpumpkins.com',
    } );

    $store->set( 'Artist' => 'Tool' => {
        name => 'Tool',
        genre => 'rock',
    } );

    $store->search( 'Artist' )->count; # 2

    my $artist = $store->get( 'Artist' => 'Smashing Pumpkins' );

    # Set up a (searchable) index on the name field
    $store->model( 'Artist' )->field( 'name' => ( index => 1 ) );
    $store->model( 'Artist' )->reindex;

    for $artist ( $store->search( 'Artist' )->order_by( 'name DESC' )->all ) {
        ...
    }

    $store->model( 'Album' )->field( 'released' => ( index => 1, isa => 'DateTime' ) );

    $store->set( 'Album' => 'Siamese Dream' => {
        artist => 'Smashing Pumpkins',
        released => DateTime->new( ... ),
    } );

    my $album = $store->get( 'Album' => 'Siamese Dream' );
    my $released = $album->{ released }; # The field is automatically inflated
    print $release->strftime( ... );

=head1 DESCRIPTION

DBIx::NoSQL is a layer over DBI that presents a NoSQLish way to store and retrieve data. You do not need to prepare a schema beforehand to start putting data into your store

Currently, it works by using JSON for serialization and SQLite as the database (though additional database support should not difficult to implement)

The API is fairly sane, though still an early "alpha." At the moment, a better name for this package might be "DBIx::NoSQLite"

=head1 USAGE

=head2 $store = DBIx::NoSQL->new

Returns a new DBIx::NoSQL store

=head2 $store->connect( $path )

Connect to (creating if necessary) the SQLite database located at C<$path>

=head2 $store->set( $model, $key, $value )

Set C<$key> (a string) to C<$value> (a HASH reference) in C<$model>

If C<$model> has index, this command will also update the index entry corresponding to C<$key>

=head2 $value = $store->get( $model, $key )

Get C<$value> matching C<$key> in C<$model>

=head2 $value = $store->delete( $model, $key )

Delete the entry matching C<$key> in C<$model>

If C<$model> has index, this command will also delete the index entry corresponding to C<$key>

=head2 ...

For additional usage, see SYNOPSIS or look at the code. More documentation forthcoming

=head1 SEE ALSO

L<KiokuDB>

L<DBIx::Class>

=cut
