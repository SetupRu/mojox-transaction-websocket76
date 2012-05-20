#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
	use_ok('MojoX::Transaction::WebSocket76') or print("Bail out!\n");
}

diag("Testing MojoX::Transaction::WebSocket76 $MojoX::Transaction::WebSocket76::VERSION, Perl $], $^X");
