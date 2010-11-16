#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use File::Temp qw/ tempfile /;
use DBIx::NoSQL;

ok( 1 );

my ( $store, $store_file );
$store_file = File::Temp->new->filename;
$store = DBIx::NoSQL->new( database => $store_file );

ok( $store );

done_testing;
