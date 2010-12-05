package DBIx::NoSQLite;
# ABSTRACT: An embedded, NoSQL SQLite database with SQL indexing

use strict;
use warnings;

use DBIx::NoSQL::Store;
use DBD::SQLite;

sub new {
    my $class = shift;
    return DBIx::NoSQL::Store->new( @_ );
}

sub connect {
    my $class = shift;
    return DBIx::NoSQL::Store->connect( @_ );
}

=head1 SYNOPSIS

    use DBIx::NoSQLite;

    my $store = DBIx::NoSQLite->connect( 'store.sqlite' );

    $store->set( ... );

    $store->get( ... );

    $store->exists( ... );

    $store->delete( ... );

    $store->search( ... );

    ...

Refer to L<DBIx::NoSQL>

=head1 DESCRIPTION

DBIx::NoSQLite a key/value store using SQLite as the backend

Refer to L<DBIx::NoSQL> for documentation and usage

=cut

1;

