package t::Test;

use strict;
use warnings;

use t::Test;
use File::Temp qw/ tempfile /;
use DBIx::NoSQL;
use Path::Class;
use DateTime;

sub tmp_sqlite {
    return file File::Temp->new->filename;
}

sub test_sqlite {
    shift;
    my %options = @_;
    my $file = file 'test.sqlite';
    $file->remove if $options{ remove };
    return $file;
}

1;
