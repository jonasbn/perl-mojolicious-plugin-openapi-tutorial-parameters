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

First we add the method for handling `/api/users`

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

Now start the application

```bash
$ morbo script/parameters
```

And finally - lets call the API

```bash
$ http http://localhost:3000/api/users
```

We should now get the result

```json
HTTP/1.1 200 OK
Content-Length: 129
Content-Type: application/json;charset=UTF-8
Date: Thu, 26 Jul 2018 18:25:34 GMT
Server: Mojolicious (Perl)

{
    "users": [
        {
            "email": "alice@eksempel.dk",
            "name": "Alice",
            "userid": "alice"
        },
        {
            "email": "bob@eksempel.dk",
            "name": "Bob",
            "userid": "bob"
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
    }
}
```

Now lets call the API

```bash
$ http http://localhost:3000/api/user?id=alice
```

And the response should resemble:

```json
HTTP/1.1 200 OK
Content-Length: 70
Content-Type: application/json;charset=UTF-8
Date: Thu, 26 Jul 2018 18:30:50 GMT
Server: Mojolicious (Perl)

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

Lets call the API

```bash
$ http http://localhost:3000/api/user/bob
```

```json
HTTP/1.1 200 OK
Content-Length: 64
Content-Type: application/json;charset=UTF-8
Date: Thu, 26 Jul 2018 18:31:45 GMT
Server: Mojolicious (Perl)

{
    "user": {
        "email": "bob@eksempel.dk",
        "name": "Bob",
        "userid": "bob"
    }
}
```

Yay! our **Mojolicious** **OpenAPI** implementation works and we can even support different URL schemas.

That is it for now, good luck with experimenting with **Mojolicious** **OpenAPI** integration and **OpenAPI**. Thanks to Jan Henning Thorsen ([@jhthorsen](https://twitter.com/jhthorsen)) for the implementation of Mojolicious::Plugin::OpenAPI.

## References

- [MetaCPAN: Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI)
- [MetaCPAN: Mojolicious::Plugin::OpenAPI Tutorial](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI::Guides::Tutorial)
- [OpenAPI Website](https://www.openapis.org/)
- [GitHub repository for tutorial](https://github.com/jonasbn/perl-mojolicious-plugin-openapi-tutorial-hello-world)
