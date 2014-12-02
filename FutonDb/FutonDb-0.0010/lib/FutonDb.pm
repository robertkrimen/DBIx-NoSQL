package FutonDb;
BEGIN {
  $FutonDb::VERSION = '0.0010';
}
# ABSTRACT: A NoSQL-ish overlay for an SQL database

use strict;
use warnings;

use Moose;

has dbh => qw/ is ro required 1 /;





1;

__END__
=pod

=head1 NAME

FutonDb - A NoSQL-ish overlay for an SQL database

=head1 VERSION

version 0.0010

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

