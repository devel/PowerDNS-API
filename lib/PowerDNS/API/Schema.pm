package PowerDNS::API::Schema;
use Moose;
with 'PowerDNS::API::Schema::_scaffold';

has '+dbic' =>
  (handles => [qw(txn_do txn_scope_guard txn_begin txn_commit txn_rollback)],);

sub connect_args {
    (   sub {
            my $config = Dancer::setting("database");
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
