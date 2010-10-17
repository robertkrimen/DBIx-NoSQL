#!/usr/bin/env perl
use warnings;
use strict;
use Test::Most;

use DBIx::NoSQL;
use DBIx::SQLite::Deploy;
use File::Temp qw/ tempfile /;
use Data::UUID::LibUUID;

my $tmp_sqlite = File::Temp->new->filename;

use constant KEY => '__key__';
use constant VALUE => '__data__';

my $deploy = DBIx::SQLite::Deploy->deploy( "$tmp_sqlite" => <<_END_ );
[% PRIMARY_KEY = "INTEGER PRIMARY KEY AUTOINCREMENT" %]
[% CLEAR %]
---
CREATE TABLE artist (

    __key__    TEXT NOT NULL,
    __data__   TEXT,
    
    UNIQUE( __key__ )
);
_END_


my( $dbh, $store, $search, $statement, $result, $key, @bind );

$store = DBIx::NoSQL->new( dbh => $dbh = $deploy->connect );

ok( $dbh->ping );

$store->source( 'artist' )->derive->before( sub {
    my $source = shift;
    my $value = shift;
    $value->{key} ||= new_uuid_string;
} );

$result = $store->put( artist => { title => 'Alice' } );
ok( $key = $result->{ &KEY } );
like( $result->{ &VALUE }, qr/Alice/ );

$result = $store->put( artist => $result->{ &KEY } => { title => 'Bob' } );
like( $result->{ &VALUE }, qr/Bob/ );

$result = $dbh->selectrow_hashref( 'SELECT * FROM artist WHERE __key__ = ?', undef, $result->{ __key__ } );
like( $result->{ &VALUE }, qr/Bob/ );

done_testing;
