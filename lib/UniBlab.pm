package UniBlab;
use 5.10.0;
use Moses;
use namespace::autoclean;
use POE::Component::Github;

server 'irc.perl.org';
channels '#bots';

has github => (
    isa        => 'POE::Component::Github',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_github { POE::Component::Github->spawn() }

sub show_user {
    my ( $self, $name, $nick, $channel ) = @_;
    $self->debug("searching for $name");
    $self->github->yield(
        'user', 'show',
        {
            event    => '_show_user',
            user     => $name,
            _channel => $channel,
            _nick    => $nick
        }
    );
}

event _show_user => sub {
    my ( $self, $resp ) = @_[ OBJECT, ARG0 ];
    my $d = $resp->{data}{user};
    $self->privmsg( $resp->{_channel} =>
            "$resp->{_nick}: $d->{login} is $d->{name} ($d->{location}) $d->{email} $d->{blog}"
    );
};

event irc_bot_addressed => sub {
    my ( $self, $nickstr, $channel, $msg ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
    my $nick = parse_user($nickstr);
    given ($msg) {
        when (/^show user (.*)/) {
            $self->show_user( $1, $nick, $channel );
        }
        default {
            $self->privmsg( $channel =>
                    "$nick: Sorry I'm not sure what to do with that" );
        }
    }
};

__PACKAGE__->run unless caller;

1;
__END__
