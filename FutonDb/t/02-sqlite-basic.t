#!/usr/bin/env perl

use Test::Most 'no_plan';

use FutonDb;
use DBIx::SQLite::Deploy;
use File::Temp;
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


my( $dbh, $futon, $search, $statement, @bind );

$futon = FutonDb->new( dbh => $dbh = $deploy->connect );

ok( $dbh->ping );

$futon->source( 'artist' )->derive->pre( sub {
    my $source = shift;
    my $value = shift;
    $value->{key} ||= new_uuid_string;
} );

$futon->set( artist => { title => 'Alice' } );
