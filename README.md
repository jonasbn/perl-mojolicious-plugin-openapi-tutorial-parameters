# Tutorial on Mojolicious::Plugin::OpenAPI: Parameters

<!-- markdownlint-disable MD014 -->

This is a follow up to [my tutorial](https://github.com/jonasbn/perl-mojolicious-plugin-openapi-tutorial-hello-world/blob/master/README.md) on Mojolicious::Plugin::OpenAPI, demonstrating the basic implementation of a Hello World example.

This tutorial with extend on the topic and will touch on parameter use.

## The Application

The application implements and demonstrates two approaches to parameter handling:

1. Query parameter based, like: `/api/user?id=alice`
1. URL parameter based, like: `/api/user/bob`

First lets generate our application:

```bash
$ mojo generate app Parameters
```

Jump into our newly generated application directory

```bash
$ cd parameters
```

We then install the plugin we need to enable **OpenAPI** in our **Mojolicious** application

Using **CPAN** shell:

```bash
$ perl -MCPAN -e shell install Mojolicious::Plugin::OpenAPI
```

Using `cpanm`:

```bash
$ cpanm Mojolicious::Plugin::OpenAPI
```

If you need help installing please refer to [the CPAN installation guide](https://www.cpan.org/modules/INSTALL.html).

Create a definition JSON file based on **OpenAPI** to support an Hello World implementation based on the **OpenAPI** specification:

```bash
$ touch openapi.conf
```

Open `openapi.conf` and insert the following _snippet_:

```json
{
    "swagger": "2.0",
    "info": { "version": "1.0", "title": "Demo of API with parameters" },
    "basePath": "/api",
    "paths": {
      "/users": {
        "get": {
          "operationId": "getUsers",
          "x-mojo-name": "get_users",
          "x-mojo-to": "user#list",
          "summary": "Lists users",
          "responses": {
            "200": {
              "description": "Users response",
              "schema": {
                "type": "object",
                "properties": {
                  "users": {
                    "type": "array",
                    "items": { "type": "object" }
                  }
                }
              }
            }
          }
        }
      },
      "/user/#id": {
        "get": {
          "operationId": "getUserByUrl",
          "x-mojo-name": "get_user_by_url",
          "x-mojo-to": "user#get_by_url",
          "summary": "User response",
          "responses": {
            "200": {
              "description": "User response",
              "schema": {
                "type": "object",
                "properties": {
                  "user": {
                    "type": "object"
                  }
                }
              }
            },
            "default": {
              "description": "Unexpected error",
              "schema": {}
            }
          }
        }
      },
      "/user": {
            "get": {
              "operationId": "getUserByParameter",
              "x-mojo-name": "get_user_by_parameter",
              "x-mojo-to": "user#get_by_parameter",
              "summary": "User response",
              "parameters": [
                {"in": "query", "name": "id", "type": "string"}
              ],
              "responses": {
                "200": {
                  "description": "User response",
                  "schema": {
                    "type": "object",
                    "properties": {
                      "user": {
                        "type": "object"
                      }
                    }
                  }
                },
                "default": {
                  "description": "Unexpected error",
                  "schema": {}
                }
              }
            }
      }
    }
  }
```

Now lets go over our definiton. We will not cover the basics as such, please refer to the Hello World tutorial, instead we will focus on the aspects related to parameters.

We have introduced 3 end-points, to simulate a more complete RESTful API.

We have defined the following paths:

- `/api/users`, returning an array of users. This is basically a variation of the Hello World example, which just returned an object where this end-point return an array of objects.

- `/api/user?id=«id»`, returning a user object if one can be found, this is based on a query parameter. Mojolicious::Plugin::OpenAPI validates this parameter based on the defintion in our `openapi.json`

- `/api/user/«id»`, returning a user object if one can be found, this is based on the URL like a proper RESTful interface, Mojolicious::Plugin::OpenAPI does **NOT** validate but the URL is somewhat validated based on the defintion in our `openapi.json`

Create a new file: `User.pm` in `lib/Parameters/Controller/`

First we add the method for handling `/api/users`:

```perl
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
```

We are simulating a model in our application, so the data are just placed in a internal data structure named: `%users`, this could of course be any sort of model, a database, filesystem or another service.

Now start the application:

```bash
$ morbo script/parameters
```

And finally - lets call the API, do note you do not need `jq` and your could use `curl` or `httpie`, so this is just for sticking to the already available tools, `jq` being the exception.

```bash
$ mojo get http://localhost:3000/api/users | jq
```

A we get a complete list of our users, currently consisting of Bob and Alice:

```json
{
  "users": [
    {
      "email": "bob@eksempel.dk",
      "name": "Bob",
      "userid": "bob"
    },
    {
      "email": "alice@eksempel.dk",
      "name": "Alice",
      "userid": "alice"
    }
  ]
}
```

Now lets add the method for handling a single user object via a query parameter:

```perl
sub get_by_parameter {

    # Do not continue on invalid input and render a default 400
    # error document.
    my $c = shift->openapi->valid_input or return;

    # $c->openapi->valid_input copies valid data to validation object,
    # and the normal Mojolicious api works as well.
    my $input = $c->validation->output;

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
}
```

Now lets call the API:

```bash
$ mojo get http://localhost:3000/api/user?id=alice | jq
```

And the result for Alice:

```json
{
  "user": {
    "email": "alice@eksempel.dk",
    "name": "Alice",
    "userid": "alice"
  }
}
```

And finally lets add the method for handling a single user object via the URL:

```perl
sub get_by_url {

    # Do not continue on invalid input and render a default 400
    # error document.
    my $c = shift->openapi->valid_input or return;

    my $id = $c->stash('id');

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
}
```

Lets call the API again using the URL:

```bash
$ mojo get http://localhost:3000/api/user/bob | jq
```

And we get the result for Bob:

```json
{
  "user": {
    "email": "bob@eksempel.dk",
    "name": "Bob",
    "userid": "bob"
  }
}
```

Yay! our **Mojolicious** **OpenAPI** implementation works and we can even support different URL schemas.

Since we take parameters, we need to do one last thing. And that is sanitizing our input. This part is not essential for get going with **Mojolicious** **OpenAPI** integration and **Mojolicious::Plugin::OpenAPI**.

This next part is not required for understanding handling parameters, but if you want get into validation, which is quite essential please read along.

Lets add validation to our two end-points processing data. The Mojolicious::Plugin::OpenAPI already has a hook for validation, but we need to extend this.

Lets add a method to our `Parameters::Controller::User`. Our `id` no matter how we receive it has to adhere to the same validation so we add this basic validation method, which overwrites the existing validation for our controller.

```perl
sub _validate_id {
    my ($c, $id) = @_;

    my $validator = $c->validation->validator;
    my $validation = $validator->validation;
    $validation->input({id => $id});
    $validation->required('id')->like(qr/^[A-Z]/i);
    $c->validation->validator($validation);

    return $c;
}
```

As you can see our two end-points fetching users are pretty similar, the only difference is how the `id` parameter is received, so lets generalise this with the following method:

```perl
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
```

We let this method call our validation method, so all we need to do is let the two end-points extract the `id` parameter and call the `_proces_request` method:

First: `get_by_parameter`:

```perl
sub get_by_parameter {

    # Do not continue on invalid input and render a default 400
    # error document.
    my $c = shift->openapi->valid_input or return;

    # $c->openapi->valid_input copies valid data to validation object,
    # and the normal Mojolicious api works as well.

    $c->_proces_request($c->param('id'));
}
```

Secondly: `get_by_parameter`:

```perl
sub get_by_url {

    # Do not continue on invalid input and render a default 400
    # error document.
    my $c = shift->openapi->valid_input or return;

    # $c->openapi->valid_input copies valid data to validation object,
    # and the normal Mojolicious api works as well.

    $c->_proces_request($c->stash('id'));
}
```

And we should be good to go. The complete controller component should look like the following:

```perl
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
```

To checkout our new validations try different variations. As we implemented we only allow lettes for user-id and hence we regard the request as a _bad request_


```bash
$ mojo get --verbose http://localhost:3000/api/user/123 | jq
GET /api/user/123 HTTP/1.1
Host: localhost:3000
Accept-Encoding: gzip
User-Agent: Mojolicious (Perl)
Content-Length: 0

HTTP/1.1 400 Bad Request
Date: Fri, 27 Jul 2018 08:25:40 GMT
Content-Type: application/json;charset=UTF-8
Server: Mojolicious (Perl)
Content-Length: 25

{
  "message": "Bad request"
}
```

And of the other end-point also a _bad request_:

```bash
$ mojo get --verbose http://localhost:3000/api/user?id=123 | jq
GET /api/user?id=123 HTTP/1.1
Host: localhost:3000
User-Agent: Mojolicious (Perl)
Accept-Encoding: gzip
Content-Length: 0

HTTP/1.1 400 Bad Request
Date: Fri, 27 Jul 2018 08:27:24 GMT
Server: Mojolicious (Perl)
Content-Type: application/json;charset=UTF-8
Content-Length: 25

{
  "message": "Bad request"
}
```

That concludes this part. Have fun experimenting with **Mojolicious::Plugin::OpenAPI**.

## References

- [MetaCPAN: Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI)
- [MetaCPAN: Mojolicious::Plugin::OpenAPI Tutorial](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI::Guides::Tutorial)
- [OpenAPI Website](https://www.openapis.org/)
- [GitHub repository for tutorial](https://github.com/jonasbn/perl-mojolicious-plugin-openapi-tutorial-parameters)
- [Mojolicious.org: Mojolicious::Validator](https://mojolicious.org/perldoc/Mojolicious/Validator)
- [Mojolicious.org: Mojolicious::Validator::Validation](https://mojolicious.org/perldoc/Mojolicious/Validator/Validation)
