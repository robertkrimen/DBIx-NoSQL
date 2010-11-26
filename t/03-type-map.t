#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use DBIx::NoSQL::TypeMap;
use DateTime;

my ( $map, $type, $data, $value );

$map = DBIx::NoSQL::TypeMap->new;
ok( $type = $map->type( 'DateTime' ) );

$data = DateTime->new( year => 2006, month => 5, day => 4, hour => 3, minute => 2, second => 1 );
is( $value = $type->deflate( $data ), '1146711721' );
is( $type->inflate( $value ).'', $data.'' );

done_testing;
