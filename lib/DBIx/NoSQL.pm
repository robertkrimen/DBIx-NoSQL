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
    $store->model( 'Artist' )->index->migrate;

    for $artist ( $store->search( 'Artist' )->order_by( 'name DESC' )->all ) {
        ...
    }


=head1 DESCRIPTION

DBIx::NoSQL is a layer over DBI that presents a NoSQLish way to store and retrieve data. You do not need to set up a schema beforehand to start putting data into your store.

Currently, it does this by using JSON for serialization and is only compatible with SQLite (though additional database support should not difficult to implement)

The API is fairly sane, though still "alpha" quality

=head1 USAGE

=head1 SEE ALSO

L<KiokuDB>

L<DBIx::Class>

=cut
