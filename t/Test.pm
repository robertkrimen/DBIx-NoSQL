package t::Test;

use strict;
use warnings;

use DBIx::NoSQL::SearchClass;

package t::Test::Artist;

use base qw/ DBIx::NoSQL::SearchClass /;

__PACKAGE__->table( 'Artist' );

1;
