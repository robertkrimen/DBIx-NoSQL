#!/usr/bin/env perl
use warnings;
use strict;
use Test::Most;

use DBIx::NoSQL;
use DBIx::SQLite::Deploy;
use File::Temp qw/ tempfile /;
use Data::UUID::LibUUID;

my $tmp_sqlite = tempfile;

my $deploy = DBIx::SQLite::Deploy->deploy( "$tmp_sqlite" => <<_END_ );
[% PRIMARY_KEY = "INTEGER PRIMARY KEY AUTOINCREMENT" %]
[% CLEAR %]
---
CREATE TABLE artist (

    __key__     TEXT NOT NULL,
    __value__   TEXT,
    
    UNIQUE( __key__ )
);
_END_


my( $dbh, $store, $search, $statement, @bind );

$store = DBIx::NoSQL->new( dbh => $dbh = $deploy->connect );

ok( $dbh->ping );

$store->source( 'artist' )->derive->before( sub {
    my $source = shift;
    my $value = shift;
    $value->{key} ||= new_uuid_string;
} );

$store->set( artist => { title => 'Alice' } );

done_testing;
