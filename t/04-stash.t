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

ok( $store->stash );

$store->stash->value( 'Xyzzy', 1 );
is( $store->stash->value( 'Xyzzy' ), 1 );

done_testing;
