#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use t::Test;
use File::Temp qw/ tempfile /;
use DBIx::NoSQL;
use Path::Class;

ok( 1 );

my ( $store, $store_file );
$store_file = File::Temp->new->filename;
$store_file = file 'test.sqlite';
$store_file->remove;
$store = DBIx::NoSQL->new( database => $store_file );

ok( $store );

$store->prepare(qw/ Artist /);

$store->type( 'Artist' )->set( 1 => { Xyzzy => 1 } );
$store->type( 'Artist' )->set( 2 => { Xyzzy => 2 } );
$store->type( 'Artist' )->set( 3 => { Xyzzy => 3 } );

is( $store->search( 'Artist', { key => 1 } )->count, 1 );
is( $store->search( 'Artist' )->count, 3 );
is( $store->search( 'Artist', { key => { -in => [qw/ 1 3 /] } } )->count, 2 );
cmp_deeply( [ $store->search( 'Artist', { key => 1 } )->fetch ], [
    { Xyzzy => 1 },
] );
#cmp_deeply( [ $store->search( 'Artist', { key => { -in => [qw/ 1 3 /] } } )->order_by(

done_testing;
