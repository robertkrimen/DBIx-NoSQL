#!/usr/bin/env perl

use Test::Most 'no_plan';

use FutonDb;
#use FutonDb::ResultSet;

my( $futon, $search, $statement, @bind );

$futon = FutonDb->new;

$search = $futon->search( artist => {} );
( $statement, @bind ) = $search->search( { name => 'Xyzzy' } )->select(qw/ * /) ;
is( "$statement\n", <<_END_ );
SELECT * FROM artist WHERE ( name = ? )
_END_
cmp_deeply( \@bind, [qw/ Xyzzy /] );

( $statement, @bind ) = $search->search( { name => 'Xyzzy' } )->value;
is( "$statement\n", <<_END_ );
SELECT __value__ FROM artist WHERE ( name = ? )
_END_
