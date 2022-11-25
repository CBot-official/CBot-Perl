
#!/usr/bin/perl -w
#

# Object interface to socket communications
use IO::Socket;

#IRC parameters
my $ircServer = 'irc.rizon.net';
my $homeChannel = '#cbot';

my $botnick = 'perl_Cbot';
my $botIdent = 'perl_Cbot';
my $botRealName = 'perl_Cbot';

# Creates a new client. Timeout is defined in seconds.
my $con = IO::Socket::INET->new(
  PeerAddr  => $ircServer,
  PeerPort  => '6667',
  Proto     => 'tcp',
  Timeout   => '240'
) or die "Error! $!\n";

sub sendIRC {
    local $msg;
    my $msg = shift;
    print $con "$msg \r\n";
}

sub sendPrivMsg {
    local $msg;
    my $to = shift;
    my $msg = shift;
    sendIRC("PRIVMSG $to :$msg");
}

sub sendPrivNot {
    local $msg;
    my $to = shift;
    my $msg = shift;
    sendIRC("NOTICE $to :$msg");
}

# Join the IRC Network
sendIRC("USER $botIdent * * $botRealName");
sendIRC("NICK $botnick");

$nick = '';
$target = '';
$message = '';

# IRC connection loop
while (my $serverMsg = <$con>)
{
    # Show server reply
    print $serverMsg;

    # Answer to server ping requests to keep connection alive
    if ($serverMsg =~ m/^PING (.*?)$/gi)
    {
        sendIRC("PONG ".$1);
    }

    # join channel after we get the welcome msg from server
    elsif ($serverMsg =~ / 001 $botnick :/)
    {
        sendIRC("JOIN $homeChannel");  
    }

    # On PRIVMSG 
    elsif ($serverMsg =~ / PRIVMSG /)
    {
        @msgSpt = split(/!/, $serverMsg);
        $nick = $msgSpt[0];
        my $nick = substr($nick, 1);

        @msgSpt = split(/ PRIVMSG /, $serverMsg);
        @msgSpt = split(/ /, $msgSpt[1]);
        $target = $msgSpt[0];

        @msgSpt = split(/ $target :/, $serverMsg);
        $message = $msgSpt[1];

        # reply to !testMsg sent to home channel
        if ($homeChannel = $target && $serverMsg =~ / :!testMsg/)
        {
            #send msg to home channel
            sendPrivMsg($target, "found testMsg");  
            sendPrivMsg($nick, "found testMsg"); 
        }
        elsif ($botnick = $target && $serverMsg =~ / :!testMsg/) 
        {
            #send msg to senders nick
            sendPrivMsg($nick, "found testMsg");    
        }

    }



}
