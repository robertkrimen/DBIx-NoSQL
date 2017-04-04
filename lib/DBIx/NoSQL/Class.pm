package DBIx::NoSQL::Class::Meta;

use strict;
use warnings;

use Moose;

has package => qw/ is ro required 1 /;

no Moose;

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
