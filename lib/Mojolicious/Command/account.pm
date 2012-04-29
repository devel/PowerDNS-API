package Mojolicious::Command::account;
use Mojo::Base 'Mojo::Command';

has description => "Setup a new user account/password.\n";
has usage       => "usage: $0 account [username] [password]\n";

sub run {
    my ($self, $user, $password) = @_;

    die $self->usage unless $user && $password;

    my $schema = $self->app->schema;

    my $account = $schema->account->find({ name => $user });

    if ($account) {
        $account->password($password);
        $account->update;
        print "Account updated\n";
    }
    else {
        $schema->account->create({ name => $user, password => $password });
        print "Account created\n";
    }

}

1;
