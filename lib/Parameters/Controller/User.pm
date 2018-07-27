package Parameters::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

my %users = (
    'bob'  => { name => 'Bob', email => 'bob@eksempel.dk' },
    'alice'=> { name => 'Alice', email => 'alice@eksempel.dk' },
);

sub list {

    # Do not continue on invalid input and render a default 400
    # error document.
    my $c = shift->openapi->valid_input or return;

    my @user_list = ();

    foreach my $user_id (keys %users) {
        my $user = $users{$user_id};
        $user->{userid} = $user_id;
        push @user_list, $user;
    }

    # $output will be validated by the OpenAPI spec before rendered
    my $output = { users => \@user_list };
    $c->render(openapi => $output);
}

sub get_by_parameter {

    # Do not continue on invalid input and render a default 400
    # error document.
    my $c = shift->openapi->valid_input or return;

    # $c->openapi->valid_input copies valid data to validation object,
    # and the normal Mojolicious api works as well.

    $c->_proces_request($c->param('id'));
}

sub get_by_url {

    # Do not continue on invalid input and render a default 400
    # error document.
    my $c = shift->openapi->valid_input or return;

    # $c->openapi->valid_input copies valid data to validation object,
    # and the normal Mojolicious api works as well.

    $c->_proces_request($c->stash('id'));
}

sub _proces_request {
    my ($c, $id) = @_;

    $c->_validate_id($id);

    if (not $c->validation->validator->has_error) {

        my $input = $c->validation->validator->output;

        my $id = $input->{'id'};
        my $user = $users{$id};

        if ($user) {
            $user->{userid} = $id;
            # $output will be validated by the OpenAPI spec before rendered
            my $output = { user => $user };
            $c->render(openapi => $output);
        } else {
            $c->respond_to(
                any => { status => 404, json => { message => 'Not found' }}
            );
        }
    } else {
        $c->respond_to(
            any => { status => 400, json => { message => 'Bad request' }}
        );
    }

    return $c;
}

sub _validate_id {
    my ($c, $id) = @_;

    my $validator = $c->validation->validator;
    my $validation = $validator->validation;
    $validation->input({id => $id});
    $validation->required('id')->like(qr/^[A-Z]/i);
    $c->validation->validator($validation);

    return $c;
}

1;
