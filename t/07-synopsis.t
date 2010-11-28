#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use t::Test;

my ( $store, $store_file, $model, $result );
$store_file = t::Test->test_sqlite( remove => 1 );;

$store = DBIx::NoSQL->new();
ok( $store );

$store->connect( $store_file );

$store->set( 'Artist' => 'Smashing Pumpkins' => {
    name => 'Smashing Pumpkins',
    genre => 'rock',
    website => 'smashingpumpkins.com',
} );

$store->set( 'Artist' => 'Tool' => {
    name => 'Tool',
    genre => 'rock',
} );

is( $store->search( 'Artist' )->count, 2 );

my $artist = $store->get( 'Artist' => 'Smashing Pumpkins' );
cmp_deeply( $artist, {
    name => 'Smashing Pumpkins',
    genre => 'rock',
    website => 'smashingpumpkins.com',
} );

$store->model( 'Artist' )->field( 'name' => ( index => 1 ) );
$store->model( 'Artist' )->reindex;

cmp_deeply( [ $store->search( 'Artist' )->order_by( 'name DESC' )->all ], [
    {
        name => 'Tool',
        genre => 'rock',
    },
    {
        name => 'Smashing Pumpkins',
        genre => 'rock',
        website => 'smashingpumpkins.com',
    },
] );

done_testing;
