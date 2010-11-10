package DBIx::NoSQL::Schema;

use strict;
use warnings;

use Any::Moose;
use JSON; our $json = JSON->new->pretty;
use Digest::SHA qw/ sha1_hex /;

extends qw/ DBIx::Class::Schema /;
our $schema = __PACKAGE__;
our $register = sub {
    my $package = caller;
    $schema->register_class( substr( $package, 10 + length $schema) =>  $package );
};
__PACKAGE__->load_namespaces;

has sql => qw/ is ro lazy_build 1 /;
sub _build_sql {
    my $self = shift;
    my $sql = $self->deployment_statements( undef, undef, undef, { add_drop_table => 1 } );
    $sql =~ s/^--[^\n]*$//gsm;
    return $sql;
}

has version => qw/ is ro lazy_build 1 /;
sub _build_version {
    my $self = shift;
    return sha1_hex( $self->sql );
}

sub deploy {
    my $self = shift;
    my $sql = $self->sql;
    my @sql = split m/;\n/, $sql;
    warn join "\n", @sql, '';
    my $dbh = $self->storage->dbh;
    $dbh->do( $_ ) for @sql;
    #$self->jourpl->database->query(
        #'INSERT INTO __meta__ (version) VALUES (?)',
        #$self->version,
    #);
}

package DBIx::NoSQL::Schema::Result::Entity;

use strict;
use warnings;

use base qw/ DBIx::Class /;

__PACKAGE__->load_components(qw/ InflateColumn::DateTime PK::Auto Core /);
__PACKAGE__->table( '__entity__' );
__PACKAGE__->add_columns(
    kind => {
        data_type => 'text',
    },
    key => {
        data_type => 'text',
    },
    value => {
        data_type => 'text',
        default_value => '{}',
    },
);
__PACKAGE__->set_primary_key(qw/ kind key /);
$register->();

1;
