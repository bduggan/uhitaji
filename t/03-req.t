#!/usr/bin/env perl6

use v6;
use lib 'lib';
use HTTP::Tinyish;

use Utiaji;
use Test;

# TODO find a port
my $port = 9999;
my $base = "http://localhost:$port";

my $u = Utiaji.new;
$u.start($port);
sleep 2;

my $ua = HTTP::Tinyish.new;
my %res = $ua.get("$base");

is %res<content>, 'Welcome to Utiaji.', 'got content';
is %res<status>, 200, 'status 200';
is %res<headers><content-type>, 'text/plain', 'content type';

%res = $ua.get("$base/no/such/place");
is %res<status>, 404, "404 not found";

