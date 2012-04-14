package PowerDNS::API::Schema;
use Moose;

with 'PowerDNS::API::Schema::_scaffold';
use DBI;

has '+dbic' =>
  (handles => [qw(txn_do txn_scope_guard txn_begin txn_commit txn_rollback)],);

our $instance;

sub instance { 
    my $class = shift;
    unless (@_) {
        return $instance ||= $class->new;
    }
    else {
        return $class->new(@_);
    }
}

sub config {
    my $self = shift;
    return { data_source => 'dbi:mysql:database=pdns',
             user => 'root'
           };
}

sub connect_args {
    my $self = shift;
    my $config = $self->config;

    (   sub {
            
            DBI->connect(
                $config->{data_source},
                $config->{user},
                $config->{password},
                {   AutoCommit        => 1,
                    RaiseError        => 1,
                    mysql_enable_utf8 => 1,
                },
            );
        },
        {   quote_char    => q{`},
            name_sep      => q{.},
            on_connect_do => [
                "SET sql_mode = 'STRICT_TRANS_TABLES'", "SET time_zone = 'UTC'",
            ],
        }
    );
}

sub dbh {
    shift->dbic->storage->dbh;
}

package PowerDNS::API::Schema::load_types;
PowerDNS::API::Schema::Record->load_type_classes;


package PowerDNS::API::Schema::Account;
use strict;

sub store_column {
    my ( $self, $name, $value ) = @_;
    if ($name eq 'password') {
        my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
        $csh->add($value);
        $value = $csh->generate;
    }
    $self->next::method($name, $value);
}

1;
