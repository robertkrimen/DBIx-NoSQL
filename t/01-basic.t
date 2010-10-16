#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use DBIx::NoSQL;
#use DBIx::NoSQL::ResultSet;

my( $store, $search, $statement, @bind );

$store = DBIx::NoSQL->new;

$search = $store->search( artist => {} );
( $statement, @bind ) = $search->search( { name => 'Xyzzy' } )->select(qw/ * /) ;
is( "$statement\n", <<_END_ );
SELECT * FROM artist WHERE ( name = ? )
_END_
cmp_deeply( \@bind, [qw/ Xyzzy /] );

( $statement, @bind ) = $search->search( { name => 'Xyzzy' } )->value;
is( "$statement\n", <<_END_ );
SELECT __value__ FROM artist WHERE ( name = ? )
_END_

done_testing;
