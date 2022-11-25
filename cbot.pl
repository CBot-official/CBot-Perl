#!/usr/bin/perl -w
#

# Object interface to socket communications
use IO::Socket;

#IRC parameters
my $ircServer = 'irc.rizon.net';
my $homeChannel = '#astalavista';

my $botnick = 'perl_Cbot';
my $botIdent = 'perl_Cbot';
my $botRealName = 'perl_Cbot by Worm';

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

sub getNick {
    local $msg;
    my $msg = shift;
    @msgSpt = split(/!/, $msg);
    $nick = $msgSpt[0];
    my $nick = substr($nick, 1);
    return $nick;
}

sub getTarget {
    local $msg;
    my $msg = shift;
    @msgSpt = split(/ PRIVMSG /, $msg);
    @msgSpt = split(/ /, $msgSpt[1]);
    $target = $msgSpt[0];
    return $target;
}

sub getMessage {
    local $msg;
    my $msg = shift;
    my $target = shift;
    @msgSpt = split(/ $target :/, $msg);
    $message = $msgSpt[1];
    return $message;
}

# Join the IRC Network
sendIRC("USER $botIdent * * $botRealName");
sendIRC("NICK $botnick");

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

#------------
# If JOIN /
#-------------------------------------
# Messages come in from IRC in the format of: ":[Nick]!~[hostname]@[IPAddress] JOIN :[channel]"
    elsif ($serverMsg =~ / JOIN :/)
    {
        $nick = getNick($serverMsg);
        @msgSpt = split(/ JOIN :/, $serverMsg);
        $target = $msgSpt[1];

        if ($homeChannel = $target)
        {sendPrivMsg($nick, "Hello $nick and welcome to $homeChannel"); }
    }

#------------
# If PRIVMSG /
#------------------------------------- 
# Messages come in from IRC in the format of: ":[Nick]!~[hostname]@[IPAddress] PRIVMSG [channel] :[message]"
    elsif ($serverMsg =~ / PRIVMSG /)
    {
        $nick = getNick($serverMsg);
        $target = getTarget($serverMsg);     
        $message = getMessage($target, $serverMsg);  

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
