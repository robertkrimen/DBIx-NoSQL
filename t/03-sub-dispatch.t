#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use DBIx::NoSQL::SubDispatch;

my ( $routine );

$routine = DBIx::NoSQL::SubDispatch->new( original => sub {
    diag "original @_";
} );

$routine->around( sub {
    my $next = shift;
    diag "around @_";
    $next->( @_, 2, 3 );
} );

$routine->around( sub {
    my $next = shift;
    diag "around @_";
    $next->( @_, 4, 5 );
} );

$routine->before( sub {
    diag "before @_";
} );

$routine->after( sub {
    diag "after @_";
} );

$routine->before( sub {
    diag "before @_";
} );


$routine->run( 1 );

ok( 1 );

done_testing;
