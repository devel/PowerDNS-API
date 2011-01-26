#!/usr/bin/env perl
use strict;
use warnings;
use local::lib;
use lib 'lib';
use PowerDNS::API::Application;

package main;
my $app = PowerDNS::API::Application->new();
return $app;

