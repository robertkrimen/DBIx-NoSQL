package DBIx::NoSQL::Class;

use strict;
use warnings;

sub import {
    my $self = shift;
    if ( @_ ) {
        my $extend = shift;
        my $package = caller;
        $self->extend( $extend, $package );
    }
}

sub extend {
    my $self = shift;
    my $extend = shift;
    my $package = shift || caller;

    my $meta = DBIx::NoSQL::Class::Meta->new( package => $package );

    $package->meta->add_attribute( _entity => qw/ is ro required 1 / );

    return unless $extend;

    $extend->( $meta );
}

package DBIx::NoSQL::Class::Meta;

use strict;
use warnings;

use Any::Moose;

has package => qw/ is ro required 1 /;

no Any::Moose;

sub has {
    my $self = shift;
    my $package = $self->package;

    my $target = shift;
    if ( ! ref $target ) {
        die "Missing name" unless defined $target && length $target;
        $target = [ $target ];
    }

    my %options = @_;

    for my $name ( @$target ) {

        my $field = $options{ field };
        $field = $name unless defined $field;
        die "Invalid field for $package.$name" unless length $field;

        my $accessor;

        my $setter = $options{ setter };
        if ( $setter ) {
            if ( $setter eq 1 ) {
                $setter = "_set_$name";
            }
            if ( ref $setter eq 'CODE' ) {
                $accessor = sub {
                    my $self = shift;
                    if ( @_ ) {
                        my $value = shift;
                        $setter->( $self, $value );
                    }
                    return $self->_entity->{ $field };
                };
            }
            else {
                $accessor = sub {
                    my $self = shift;
                    if ( @_ ) {
                        my $value = shift;
                        $self->$setter( $value );
                    }
                    return $self->_entity->{ $field };
                };
            }
        }
        else {
            $accessor = sub {
                my $self = shift;
                if ( @_ ) {
                    die "Missing setter for ( $package.$name [ $field ] )";
                }
                return $self->_entity->{ $field };
            };
        }

        {
            no strict 'refs';
            *{"${package}::${name}"} = $accessor;
        }
    }
}

1;
