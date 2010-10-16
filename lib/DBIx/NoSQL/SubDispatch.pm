package DBIx::NoSQL::SubDispatch;

use strict;
use warnings;

use Any::Moose;

has original => qw/ is ro required 1 isa CodeRef /;
has _table => qw/ is rw isa Maybe[HashRef] /;
has _run => qw/ is rw isa Maybe[CodeRef] lazy_build 1 /;
sub _build__run { shift->original }

no Any::Moose;

sub _install_modifier {
    my ( $self, $type, $code ) = @_;

    my $original = $self->original;
    my $table = $self->_table;

    if ( !$table ) {
        my ( @before, @after, @around );
        my $cache = $original;
        my $run = sub {
            if( @before ) {
                for my $code ( @before ) { $code->(@_) }
            }
            unless( @after ) {
                return $cache->(@_);
            }

            if ( wantarray ) {
                my @return = $cache->(@_);

                for my $code ( @after ){ $code->(@_) }
                return @return;
            }
            elsif ( defined wantarray ) {
                my $return = $cache->(@_);

                for my $code ( @after ){ $code->(@_) }
                return $return;
            }
            else {
                $cache->(@_);

                for my $code ( @after ){ $code->(@_) }
                return;
            }
        };

        $table = {
            original => $original,

            before   => \@before,
            after    => \@after,
            around   => \@around,

            cache    => \$cache,
        };

        $self->_table( $table );
        $self->_run( $run );
    }

    if ( $type eq 'before' ) {
        unshift @{ $table->{ before } }, $code;
    }
    elsif ( $type eq 'after' ) {
        push @{ $table->{ after } }, $code;
    }
    else { # around
        push @{ $table->{ around } }, $code;

        my $next = ${ $table->{cache} };
        ${ $table->{cache} } = sub { $code->( $next, @_ ) };
    }

    return;
}

sub run {
    my $self = shift;
    return $self->_run->( @_ );
}

sub before {
    my ( $self, $code ) = @_;
    $self->_install_modifier( 'before', $code );
}

sub after {
    my ( $self, $code ) = @_;
    $self->_install_modifier( 'after', $code );
}

sub around {
    my ( $self, $code ) = @_;
    $self->_install_modifier( 'around', $code );
}


1;

__END__

sub _install_modifier {
    my( $self, $type, $name, $code ) = @_;
    my $into = $self->name;

    my $original = $into->can($name)
        or $self->throw_error("The method '$name' was not found in the inheritance hierarchy for $into");

    my $modifier_table = $self->{modifiers}{$name};

    if(!$modifier_table){
        my(@before, @after, @around);
        my $cache = $original;
        my $modified = sub {
            if(@before) {
                for my $c (@before) { $c->(@_) }
            }
            unless(@after) {
                return $cache->(@_);
            }

            if(wantarray){ # list context
                my @rval = $cache->(@_);

                for my $c(@after){ $c->(@_) }
                return @rval;
            }
            elsif(defined wantarray){ # scalar context
                my $rval = $cache->(@_);

                for my $c(@after){ $c->(@_) }
                return $rval;
            }
            else{ # void context
                $cache->(@_);

                for my $c(@after){ $c->(@_) }
                return;
            }
        };

        $self->{modifiers}{$name} = $modifier_table = {
            original => $original,

            before   => \@before,
            after    => \@after,
            around   => \@around,

            cache    => \$cache, # cache for around modifiers
        };

        $self->add_method($name => $modified);
    }

    if($type eq 'before'){
        unshift @{$modifier_table->{before}}, $code;
    }
    elsif($type eq 'after'){
        push @{$modifier_table->{after}}, $code;
    }
    else{ # around
        push @{$modifier_table->{around}}, $code;

        my $next = ${ $modifier_table->{cache} };
        ${ $modifier_table->{cache} } = sub{ $code->($next, @_) };
    }

    return;
}

sub add_before_method_modifier {
    my ( $self, $name, $code ) = @_;
    $self->_install_modifier( 'before', $name, $code );
}

sub add_around_method_modifier {
    my ( $self, $name, $code ) = @_;
    $self->_install_modifier( 'around', $name, $code );
}
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
