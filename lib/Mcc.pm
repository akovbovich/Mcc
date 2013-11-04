package Mcc;

use Moo;
use Coro;
use Coro::Handle;
use Coro::Channel;
use Coro::AnyEvent;
use Coro::Storable;
use AnyEvent::Socket;

use String::CRC32;
use Carp 'verbose';
use 5.10.1;

use constant F_STORABLE => 1;

our $VERSION = '0.01';

has _hostport     => (is => 'ro', init_arg => 'server', required => 1);
has _get_sock     => (is => 'ro', lazy => 1, builder => '_mk_sock');
has _set_sock     => (is => 'ro', lazy => 1, builder => '_mk_sock');
has _get_queue    => (is => 'ro', default => sub { new Coro::Channel; });
has _set_queue    => (is => 'ro', default => sub { new Coro::Channel; });
has _srv_get_mbox => (is => 'ro', default => sub { new Coro::Channel 1024; });
has _srv_set_mbox => (is => 'ro', default => sub { new Coro::Channel 1024; });

sub BUILD {
    my $self = shift;

    eval {                                                        # force socket connect
        defined $self->_get_sock and
        defined $self->_set_sock;
    } or do {
        Carp::croak "Error: $@";
    };

    my ($line, $reader, $cli_mbox) =
       (    0,       1,         2);

    my ($rc, $reason) =
       (  0,       1);

    my $mk_sender_thread = sub {
        my ($mbox, $sock, $queue) = @_;
        async {
            while () {
                my $msg = $mbox->get;
                my $nbytes = $sock->print($msg->[$line]);
                Carp::croak "Cannot write on socket" unless $nbytes;
                $queue->put($msg);
            }
        };
    };

    my $mk_receiver_thread = sub {
        my ($sock, $queue) = @_;
        async {
            while () {
                my $msg = $queue->get;
                my $bytes = $sock->readline("\r\n");
                Carp::croak "Cannot read from socket" unless $bytes;
                my $res = $msg->[$reader]->($bytes);
              MATCH:
                for ($res->[$rc]) {
                    when ('more') {
                        $bytes = $sock->readline("\r\n");
                        Carp::croak "Cannot read from socket" unless $bytes;
                        $res = $res->[$reader]->($bytes);
                        goto MATCH;
                    }
                    default {
                        $msg->[$cli_mbox]->put($res);
                    }
                }
            }
        };
    };

    $mk_sender_thread->(                                          # get requests
        $self->_srv_get_mbox,
        $self->_get_sock,
        $self->_get_queue
        );

    $mk_receiver_thread->(                                        # get responses
        $self->_get_sock,
        $self->_get_queue
        );

    $mk_sender_thread->(                                          # set requests
        $self->_srv_set_mbox,
        $self->_set_sock,
        $self->_set_queue
        );

    $mk_receiver_thread->(                                        # set responses
        $self->_set_sock,
        $self->_set_queue
        );

    ();
}

sub _mk_sock {
    my $self = shift;
    my ($host, $port) = split qr/\:/, $self->_hostport;
    tcp_connect $host, $port, Coro::rouse_cb;
    unblock +(Coro::rouse_wait)[0] or Carp::croak "Cannot connect: $host:$port";;
}

sub _hashkey { (crc32($_[0]) >> 16) & 0x7fff; }

sub _mk_any {
    my ($funs) = @_;
    sub {
        my $data = shift;
        _mk_any_fn($funs, $data, 'unexpected');
    };
}

sub _mk_any_fn {
    my ($funs, $data, $error) = @_;
    return [error => $error] unless @$funs;
    my ($rc, $reason) =
       (  0,       1);
    my $fn = shift @$funs;
    my $res = $fn->($data);
    for ($res->[$rc]) {
        when ('error') {
            for ($res->[$reason]) {
                when ('notfound') { return $res; }
                default           { return _mk_any_fn($funs, $data, $res->[$reason]); }
            }
        }
        default {
            return $res;
        }
    }
}

sub _mk_expect_response {
    my ($bin, $response) = @_;
    sub {
        my $data = shift;
        return $response if $bin eq $data;
        [error => 'unexpected'];
    };
}

sub _mk_expect_value {
    sub {
        my $data = shift;
        my ($token, $_key, $flags, $nbytes) = split qr/\ /, $data;
        return [error => 'unexpected'] if $token ne 'VALUE';
        [more => _mk_expect_body("", $flags, $nbytes, $nbytes + 2)];
    };
}

sub _mk_expect_body {
    my ($acc, $flags, $nbytes, $nbytes_togo) = @_;
    sub {
        my $data = shift;
        use bytes;
        my $len = length $data;
        if ($len < $nbytes_togo) {
            $acc .= $data;
            return [more => _mk_expect_body($acc, $flags, $nbytes, $nbytes_togo - $len)];
        }
        $acc .= $data;
        $acc = thaw $acc if $flags & F_STORABLE;
        [more => _mk_expect_response("END\r\n", [ok => $acc])];
    };
}

sub get {
    my ($self, $key) = @_;
    my $cli_mbox = new Coro::Channel 1;
    my $reader =
        _mk_any([_mk_expect_response("END\r\n", [error => 'notfound']),
                 _mk_expect_value()]);
    $key = _hashkey($key);
    my $line = "get $key\r\n";
    $self->_srv_get_mbox->put([$line, $reader, $cli_mbox]);
    $cli_mbox->get;
}

sub set {
    my ($self, $key, $val, $exp) = @_;
    my $cli_mbox = new Coro::Channel 1;
    my $reader =
        _mk_any([_mk_expect_response("STORED\r\n", [ok => 'stored']),
                 _mk_expect_response("NOT_STORED\r\n", [error => 'notstored'])]);
    $exp //= 0;
    $key = _hashkey($key);
    my $flags = 0;
    if (ref $val) {
        $val = nfreeze $val;
        $flags |= F_STORABLE;
    }
    use bytes;
    my $len = length $val;
    my $line = "set $key $flags $exp $len\r\n$val\r\n";
    $self->_srv_set_mbox->put([$line, $reader, $cli_mbox]);
    $cli_mbox->get;
}

1;
