#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use t::Test;

my ( $store, $store_file, $model );
$store_file = t::Test->test_sqlite( remove => 1 );;
$store = DBIx::NoSQL->new();

ok( $store );

