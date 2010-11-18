#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use t::Test;
use File::Temp qw/ tempfile /;
use DBIx::NoSQL;
use Path::Class;
use DateTime;

ok( 1 );

my ( $store, $store_file, $model );
$store_file = File::Temp->new->filename;
$store_file = file 'test.sqlite';
$store_file->remove;
$store = DBIx::NoSQL->new( database => $store_file );

ok( $store );

$store->prepare(qw/ Artist /);
$model = $store->model( 'Album' );
$model->field( name => ( index => 1 ) );
$model->field( date => ( index => 1, isa => 'DateTime' ) );
$model->prepare;

$store->model( 'Artist' )->set( 1 => { Xyzzy => 1 } );
$store->model( 'Artist' )->set( 2 => { Xyzzy => 2 } );
$store->model( 'Artist' )->set( 3 => { Xyzzy => 3 } );

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

done_testing;
