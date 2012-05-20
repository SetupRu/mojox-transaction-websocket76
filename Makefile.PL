#!/usr/bin/env perl

use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
	NAME          => 'MojoX::Transaction::WebSocket76',
	AUTHOR        => 'Denis Ibaev <dionys@cpan.org>',
	VERSION_FROM  => 'lib/MojoX/Transaction/WebSocket76.pm',
	ABSTRACT_FROM => 'lib/MojoX/Transaction/WebSocket76.pm',
	LICENSE       => 'perl',
	META_MERGE    => {
		requires  => {perl => '5.010001'},
		resources => {
			license     => 'http://dev.perl.org/licenses/',
			repository  => 'http://github.com/dionys/mojox-transaction-websocket76',
			bugtracker  => 'http://github.com/dionys/mojox-transaction-websocket76/issues',
		},
		no_index  => {directory => ['t']},
	},
	PREREQ_PM     => {
		'Mojolicious' => '2.52',
		'Test::More'  => 0,
	},
	dist          => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	clean         => {FILES => 'MojoX-Transaction-WebSocket76-*'},
	test          => {TESTS => 't/*.t'},
);