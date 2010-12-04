#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use t::Test;

my ( $store, $store_file, $model );
$store_file = t::Test->tmp_sqlite;
#$store_file = t::Test->test_sqlite( remove => 1 );

$store = DBIx::NoSQL->new();

ok( $store );

$store->connect( $store_file );

throws_ok { $store->storage->do( 'Xyzzy' ) } qr/syntax error \[for Statement "Xyzzy"\]/;

$model = $store->model( 'Album' );
$model->field( name => ( index => 1 ) );
$model->field( date => ( index => 1 ) );

$store->model( 'Artist' )->set( 1 => { Xyzzy => 1 } );
$store->model( 'Artist' )->set( 2 => { Xyzzy => 2 } );
$store->model( 'Artist' )->set( 3 => { Xyzzy => 3 } );

is( $store->search( 'Artist', { key => 1 } )->count, 1 );
is( $store->search( 'Artist' )->count, 3 );
is( $store->search( 'Artist', { key => { -in => [qw/ 1 3 /] } } )->count, 2 );
cmp_deeply( [ $store->search( 'Artist', { key => 1 } )->fetch ], [
    { Xyzzy => 1 },
] );

cmp_deeply( $store->model( 'Artist' )->get( 1 ), { Xyzzy => 1 } );

$store->model( 'Album' )->set( 3 => { name => 'Xyzzy', date => '20010101' } );
$store->model( 'Album' )->set( 4 => { name => 'Xyzz_' } );

cmp_deeply( [ $store->search( 'Album', { name => 'Xyzzy' } )->fetch ], [
    { name => 'Xyzzy', date => re(qr/^\d+$/), },
] );
is( $store->search( 'Album', { name => { -like => 'Xyz%' } } )->count, 2 );

is( ( $store->search( 'Artist' )->order_by( 'key DESC' )->prepare )[0],
    "SELECT __Store__.__value__ FROM Artist me JOIN __Store__ __Store__ ON ( __Store__.__key__ = me.key AND __Store__.__model__ = 'Artist' ) ORDER BY key DESC" );

is( ( $store->search( 'Artist' )->order_by([ 'key DESC', 'name' ])->prepare )[0],
    "SELECT __Store__.__value__ FROM Artist me JOIN __Store__ __Store__ ON ( __Store__.__key__ = me.key AND __Store__.__model__ = 'Artist' ) ORDER BY key DESC, name" );

$store->delete( 'Artist' => 3 );
is( $store->get( 'Artist' => 3 ), undef );
is( $store->search( 'Artist', { key => { -in => [qw/ 1 3 /] } } )->count, 1 );

done_testing;
