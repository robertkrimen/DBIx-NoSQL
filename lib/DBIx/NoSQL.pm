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

    $store->search( 'Artist' )->count; # 1

    my $artist = $store->get( 'Artist' => 'Smashing Pumpkins' );

=head1 DESCRIPTION

DBIx::NoSQL is a layer over DBI that presents a NoSQLish way to store and retrieve data. You do not need to set up a schema beforehand to start putting data into your store.

Currently, it does this by using JSON for serialization and is only compatible with SQLite (though additional database support should not difficult to implement)

The API is fairly sane, though still "alpha" quality

=head1 USAGE

=head1 SEE ALSO

L<KiokuDB>

L<DBIx::Class>

=cut
