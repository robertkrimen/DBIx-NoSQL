package DBIx::NoSQL::Stash;

use strict;
use warnings;

use Any::Moose;
use Carp qw/ cluck /;

has store => qw/ is ro required 1 weak_ref 1 /;

has model => qw/ is ro lazy_build 1 /;
sub _build_model {
    my $self = shift;
    my $model = $self->store->model( '__Store_Stash__' );
    $model->searchable( 0 );
    return $model;
}

sub value {
    my $self = shift;
    my $key = shift;
    if ( @_ ) {
        my $value = shift;
        $self->model->set( $key, { value => $value } );
        return;
    }
    my $value = $self->model->get( $key );
    return unless $value;
    return $value->{ value };
}


1;
