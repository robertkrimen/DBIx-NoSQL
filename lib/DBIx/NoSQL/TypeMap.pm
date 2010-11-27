package DBIx::NoSQL::TypeMap;

use strict;
use warnings;

use Any::Moose;

has _map => qw/ is ro isa HashRef /, default => sub { {} };

sub BUILD {
    my $self = shift;

    $self->create( 'DateTime',
        inflate => sub { return DateTime->from_epoch( epoch => $_[0] ) },
        deflate => sub { return $_[0]->epoch },
    );
}

sub type {
    my $self = shift;
    my $name = shift;

    return $self->_map->{ $name };
}

#has _cache => qw/ is rw isa HashRef /, default => sub { {} };
#sub find {
    #my $self = shift;
    #my $package = shift;

    #my $type;
    #my $cache = $self->_cache;
    #while( ! $type ) {
    #}
#}

sub create {
    my $self = shift;
    my $name = shift;

    die "Already have type ($name)" if $self->_map->{ $name };

    my $type = $self->_map->{ $name } = DBIx::NoSQL::TypeMap::Type->new( name => $name, @_ );
    return $type;
}

package DBIx::NoSQL::TypeMap::Type;

use Any::Moose;

has name => qw/ is ro required 1 isa Str /;

has inflate => qw/ accessor _inflate isa Maybe[CodeRef] /;
has deflate => qw/ accessor _deflate isa Maybe[CodeRef] /;
sub inflator { return shift->_inflate( @_ ) }
sub deflator { return shift->_deflate( @_ ) }

sub inflate { return $_[0]->_inflate->( $_[1] ) }
sub deflate { return $_[0]->_deflate->( $_[1] ) }

1;
