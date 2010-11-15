package DBIx::NoSQL::Schema;

use strict;
use warnings;

use Any::Moose;
use JSON; our $json = JSON->new->pretty;
use Digest::SHA qw/ sha1_hex /;

use DBIx::Class::ResultClass::HashRefInflator;

extends qw/ DBIx::Class::Schema /;
our $schema = __PACKAGE__;
our $register = sub {
    my $package = caller;
    $schema->register_class( substr( $package, 10 + length $schema) =>  $package );
};
__PACKAGE__->load_namespaces;

has sql => qw/ is ro lazy_build 1 /;
sub _build_sql {
    return shift->generate_sql;
}

sub generate_sql {
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

package DBIx::NoSQL::Schema::Result::__Entity__;

use strict;
use warnings;

use base qw/ DBIx::Class::Core /;

__PACKAGE__->table( '__Entity__' );
__PACKAGE__->add_columns(
    __moniker__ => {
        data_type => 'text',
    },
    __key__ => {
        data_type => 'text',
    },
    __value__ => {
        data_type => 'text',
        default_value => '{}',
    },
);
__PACKAGE__->set_primary_key(qw/ __moniker__ __key__ /);
$register->();

1;

__END__
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
