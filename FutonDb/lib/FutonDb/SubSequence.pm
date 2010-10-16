package FutonDb::SubSequence;

use strict;
use warnings;

use Any::Moose;

has [qw/ beforelist afterlist aroundlist prelist postlist /] =>
    qw/ is ro lazy 1 isa ArrayRef[CodeRef] /, default => sub { [] };

sub call {
    my $self = shift;
    my $code = shift;
    my @arguments = @_;

    if ( $self->beforelist->[0] ) {
        $self->_call( $self->beforelist, [ @arguments ] );
    }

    my @return;
    if ( $self->aroundlist->[0] ) {
        my $inner = sub { return $self->_call_inner( $code, \@arguments ) };
        @return = $self->_call( $self->aroundlist, [ $inner => @arguments ] );
    }
    else {
        @return = $self->_call_inner( $code, \@arguments );
    }

    if ( $self->afterlist->[0] ) {
        $self->_call( $self->afterlist, [ @arguments ] );
    }

    return wantarray ? @return : $return[0];
}

sub _call {
    my $self = shift;
    my $codelist = shift;
    my $arguments = shift;
    my @return;
    for my $code ( @$codelist ) {
        @return = $code->( @$arguments );
    }
    return @return;
}

sub _call_inner {
    my $self = shift;
    my $inner = shift;
    my $arguments = shift;

    if ( $self->prelist->[0] ) {
        $self->_call( $self->prelist, [ @$arguments ] );
    }

    my @return = $inner->( @$arguments );

    if ( $self->postlist->[0] ) {
        $self->_call( $self->postlist, [ @$arguments ] );
    }

    return @return;
}

sub pre {
    my $self = shift;
    my $code = shift;
    push @{ $self->prelist }, $code;
}

package FutonDb::SubSequence::Stack;

use Any::Moose;

1;
