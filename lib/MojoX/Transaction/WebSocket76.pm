package MojoX::Transaction::WebSocket76;

use Mojo::Util ('md5_bytes');

use Mojo::Base 'Mojo::Transaction::WebSocket';


our $VERSION = '0.02';


use constant DEBUG => &Mojo::Transaction::WebSocket::DEBUG;

use constant {
	TEXT   => &Mojo::Transaction::WebSocket::TEXT,
	BINARY => &Mojo::Transaction::WebSocket::BINARY,
	CLOSE  => &Mojo::Transaction::WebSocket::CLOSE,
};


sub build_frame {
	my ($self, undef, undef, undef, undef, $type, $bytes) = @_;

	warn("BUILDING FRAME\n") if DEBUG;

	my $length = length($bytes);

	if (DEBUG) {
		warn('TYPE: ', $type, "\n");
		warn('LENGTH: ', $length, "\n");
		if ($length) {
			warn('BYTES: ', $bytes, "\n");
		}
		else {
			warn("NOTHING\n")
		}
	}

	return "\xff" if $type == CLOSE;
	return "\x00" . $bytes . "\xff";
}

sub parse_frame {
	my ($self, $buffer) = @_;

	warn("PARSING FRAME\n") if DEBUG;

	my $index = index($$buffer, "\xff");

	return if $index < 0;

	my $type   = $index == 0 ? CLOSE : TEXT;
	my $length = $index - 1;
	my $bytes  = $length
			? substr(substr($$buffer, 0, $index + 1, ''), 1, $length)
			: '';

	if (DEBUG) {
		warn('TYPE: ', $type, "\n");
		warn('LENGTH: ', $length, "\n");
		if ($length) {
			warn('BYTES: ', $bytes, "\n");
		}
		else {
			warn("NOTHING\n")
		}
	}

	# Result does compatible with Mojo::Transaction::WebSocket.
	return [1, 0, 0, 0, $type, $bytes];
}

sub server_handshake {
	my ($self) = @_;

	my $req = $self->req;
	my $content = $req->content;

	# Fetch request body.
	$content->headers->content_length(length($content->leftovers));
	$content->parse_body_once();

	my $res = bless($self->res, 'MojoX::Transaction::WebSocket76::_Response');
	my $headers = $req->headers;

	$res->code(101);
	$res->message('WebSocket Protocol Handshake');
	$res->body(
		$self->_challenge(
			scalar($headers->header('Sec-WebSocket-Key1')),
			scalar($headers->header('Sec-WebSocket-Key2')),
			$req->body # Key3 data.
		)
	);

	my $url      = $req->url;
	my $scheme   = $url->to_abs->scheme eq 'https' ? 'wss' : 'ws';
	my $location = $url->to_abs->scheme($scheme)->to_string();
	my $origin   = $headers->header('Origin');
	my $protocol = $headers->sec_websocket_protocol;

	$headers = $res->headers;
	$headers->upgrade('WebSocket');
	$headers->connection('Upgrade');
	$headers->header('Sec-WebSocket-Location' => $location);
	$headers->sec_websocket_origin($origin) if $origin;
	$headers->sec_websocket_protocol($protocol) if $protocol;

	return $self;
}

sub _challenge {
	my ($self, $key1, $key2, $key3) = @_;

	return unless $key1 && $key2 && $key3;
	return md5_bytes(join('',
		pack('N', join('', $key1 =~ /(\d)/g) / ($key1 =~ tr/\ //)),
		pack('N', join('', $key2 =~ /(\d)/g) / ($key2 =~ tr/\ //)),
		$key3
	));
}


1;


package MojoX::Transaction::WebSocket76::_Response;

use Mojo::Base 'Mojo::Message::Response';


sub fix_headers {
	my ($self) = @_;

	$self->SUPER::fix_headers(@_[1 .. $#_]);
	# Suppress "Content-Length" header.
	$self->headers->remove('Content-Length');

	return $self;
}


1;


__END__

=head1 NAME

MojoX::Transaction::WebSocket76 - WebSocket version hixie-76 transaction
container

=head1 SYNOPSIS

    use MojoX::Transaction::WebSocket76;

    my $ws = MojoX::Transaction::WebSocket76->new;

=head1 DESCRIPTION

MojoX::Transaction::WebSocket76 is a container for WebSocket transactions as
described in L<hixie-76 draft|http://tools.ietf.org/html/draft-hixie-thewebsocketprotocol-76>.
Support for this version of the protocol was removed in L<Mojolicious> 1.17. But
last version of the Safari browser (5.0.1) supports only it.

To support for both versions of the protocol (last and hixie-76 draft) in your
Mojolicious application, add:

    # In application module.
    package MyApp;

    # Override Mojolicious::build_tx().
    sub build_tx {
        my ($self) = @_;
        # Use your own transaction module.
        my $tx = MyApp::Transaction->new;
        $self->plugins->emit_hook(after_build_tx => $tx, $self);
        return $tx;
    }

    # In transaction module.
    package MyApp::Transaction;

    use Mojo::Transaction::WebSocket;
    use MojoX::Transaction::WebSocket76;

    use Mojo::Base 'Mojo::Transaction::HTTP';

    # Override Mojo::Transaction::HTTP::server_read().
    sub server_read {
        # ...
        # Need to change only this piece of code.
        if (lc($req->headers->upgrade || '') eq 'websocket') {
            # Upgrade to WebSocket of needed version.
            $self->emit(upgrade =>
                  ($req->headers->header('Sec-WebSocket-Key1')
                && $req->headers->header('Sec-WebSocket-Key2'))
                    ? MojoX::Transaction::WebSocket76->new(handshake => $self)
                    : Mojo::Transaction::WebSocket->new(handshake => $self)
            );
        }
        # ...
    }

=head1 EVENTS

MojoX::Transaction::WebSocket76 inherits all events from
L<Mojo::Transaction::WebSocket>.

=head1 ATTRIBUTES

MojoX::Transaction::WebSocket76 inherits all attributes from
L<Mojo::Transaction::WebSocket>.

=head1 METHODS

MojoX::Transaction::WebSocket76 inherits all methods from
L<Mojo::Transaction::WebSocket>.

=head1 DEBUGGING

You can set the C<MOJO_WEBSOCKET_DEBUG> environment variable to get some
advanced diagnostics information printed to STDERR.

    MOJO_WEBSOCKET_DEBUG=1

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Transaction::WebSocket>.

=head1 SUPPORT

=over 4

=item Repository

L<http://github.com/dionys/mojox-transaction-websocket76>

=item Bug tracker

L<http://github.com/dionys/mojox-transaction-websocket76/issues>

=back

=head1 AUTHOR

Denis Ibaev, C<dionys@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Denis Ibaev.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut
