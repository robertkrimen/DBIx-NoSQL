#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use t::Test;

my ( $store, $store_file, $model );
$store_file = t::Test->test_sqlite( remove => 1 );;
$store = DBIx::NoSQL->new();

ok( $store );

$model = $store->model( 'Artist' );
$model->field( name => ( index => 1 ) );
$model->field( date => ( index => 1, isa => 'DateTime' ) );

$store->connect( $store_file );

$store->model( 'Artist' )->set( 1 => { Xyzzy => 1 } );

done_testing;
