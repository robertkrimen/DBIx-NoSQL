#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use t::Test;
use File::Temp qw/ tempfile /;
use DBIx::NoSQL;
use Path::Class;

ok( 1 );

my ( $store, $schema_file );
$schema_file = File::Temp->new->filename;
$schema_file = file 'test.sqlite';
$schema_file->remove;
$store = DBIx::NoSQL->new( schema_file => $schema_file );

ok( $store );

$store->source( 'Artist' )->register_search_class( 't::Test::Artist' );
$store->source( 'Artist' )->entity_search_source->deploy;

$store->source( 'Artist' )->set( 1 => { Xyzzy => 1 } );
$store->source( 'Artist' )->set( 2 => { Xyzzy => 2 } );
$store->source( 'Artist' )->set( 3 => { Xyzzy => 3 } );

$store->schema->resultset( 'Artist' )->search({ key => 1 });

is( $store->search( 'Artist', { key => 1 } )->count, 1 );
is( $store->search( 'Artist' )->count, 3 );
is( $store->search( 'Artist', { key => { -in => [qw/ 1 3 /] } } )->count, 2 );

done_testing;
