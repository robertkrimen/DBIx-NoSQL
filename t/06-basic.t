#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use t::Test;

my ( $store, $store_file, $model, $result );
$store_file = t::Test->tmp_sqlite;
#$store_file = t::Test->test_sqlite( remove => 1 );
$store = DBIx::NoSQL->new();

ok( $store );

$model = $store->model( 'Artist' );
$model->field( name => ( index => 1 ) );
$model->field( date => ( index => 1, isa => 'DateTime' ) );

$store->connect( $store_file );

$store->set( 'Artist', 1 => { Xyzzy => 1 } );
is( $store->search( 'Artist' )->count, 1 );

$store->set( 'Artist', 2 => { Xyzzy => 2, rank2 => 3 } );
is( $store->search( 'Artist' )->count, 2 );
is( $store->search( 'Artist', { key => 1 } )->count, 1 );

$result = $store->get( 'Artist', 2 );
cmp_deeply( $result, { Xyzzy => 2, rank2 => 3 } );

done_testing;
