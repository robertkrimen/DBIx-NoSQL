#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use t::Test;

my ( $store, $store_file, $model );
$store_file = t::Test->tmp_sqlite;
#$store_file = t::Test->test_sqlite( remove => 1 );
$store = DBIx::NoSQL->new( database => $store_file );

ok( $store );

$model = $store->model( 'Artist' );
$model->field( Xyzzy => ( index => 1 ) );
$model->field( date => ( index => 1, isa => 'DateTime' ) );

$store->model( 'Artist' )->set( 1 => { Xyzzy => 1, rank => 'rank2' } );
$store->model( 'Artist' )->set( 2 => { Xyzzy => 2, rank => 'rank1' } );
$store->model( 'Artist' )->set( 3 => { Xyzzy => 3 } );

$model->field( rank => ( index => 1 ) );

$store->reindex;

cmp_deeply( [ $store->search( 'Artist' )->order_by( 'rank' )->fetch ], [
    { Xyzzy => 3 },
    { Xyzzy => 2, rank => 'rank1' },
    { Xyzzy => 1, rank => 'rank2' },
] );

done_testing;

__END__

is( $store->search( 'Artist', { key => 1 } )->count, 1 );
is( $store->search( 'Artist' )->count, 3 );
is( $store->search( 'Artist', { key => { -in => [qw/ 1 3 /] } } )->count, 2 );
cmp_deeply( [ $store->search( 'Artist', { key => 1 } )->fetch ], [
    { Xyzzy => 1 },
] );
#cmp_deeply( [ $store->search( 'Artist', { key => { -in => [qw/ 1 3 /] } } )->order_by(

cmp_deeply( $store->model( 'Artist' )->get( 1 ), { Xyzzy => 1 } );

$store->model( 'Album' )->set( 3 => { name => 'Xyzzy', date => DateTime->now } );
$store->model( 'Album' )->set( 4 => { name => 'Xyzz_' } );

cmp_deeply( [ $store->search( 'Album', { name => 'Xyzzy' } )->fetch ], [
    { name => 'Xyzzy', date => re(qr/^\d+$/), },
] );
is( $store->search( 'Album', { name => { -like => 'Xyz%' } } )->count, 2 );

is( ( $store->search( 'Artist' )->order_by( 'key DESC' )->prepare )[0],
    "SELECT __Store__.__value__ FROM Artist me JOIN __Store__ __Store__ ON ( __Store__.__key__ = me.key AND __Store__.__model__ = 'Artist' ) ORDER BY key DESC" );

is( ( $store->search( 'Artist' )->order_by([ 'key DESC', 'name' ])->prepare )[0],
    "SELECT __Store__.__value__ FROM Artist me JOIN __Store__ __Store__ ON ( __Store__.__key__ = me.key AND __Store__.__model__ = 'Artist' ) ORDER BY key DESC, name" );

done_testing;
