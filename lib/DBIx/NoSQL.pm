package DBIx::NoSQL;
# ABSTRACT: Experimental NoSQL-ish overlay for an SQL database

use strict;
use warnings;

use DBIx::NoSQL::Store;

sub new {
    my $class  = shift;
    return DBIx::NoSQL::Store->new( @_ );
}

1;
