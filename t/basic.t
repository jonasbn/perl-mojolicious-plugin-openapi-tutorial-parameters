use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Parameters');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

$t->get_ok('/api')
  ->status_is(200)
  ->json_has('users')
  ->json_has('user')
  ->json_has('200');

$t->get_ok('/api/users')
  ->status_is(200)
  ->json_has('/users')
  ->json_has('bob')
  ->json_has('alice');

$t->get_ok('/api/user?id=bob')
  ->status_is(200)
  ->json_has('/user')
  ->json_is('/user/email', 'bob@eksempel.dk')
  ->json_is('/user/userid', 'bob')
  ->json_is('/user/name', 'Bob');

$t->get_ok('/api/user/alice')
  ->status_is(200)
  ->json_has('/user')
  ->json_is('/user/email', 'alice@eksempel.dk')
  ->json_is('/user/userid', 'alice')
  ->json_is('/user/name', 'Alice');

done_testing();
