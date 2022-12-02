#!/usr/bin/perl -w
#

use Nice::Try;
use IO::Socket;

require "config.pl";

# Creates a new client connection. Timeout is defined in seconds.
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

# finish joining the IRC Network
sendIRC("USER $botIdent * * $botRealName");
sendIRC("NICK $botnick");

# IRC connection loop
while (my $serverMsg = <$con>)
{
    # Keep the bot runiing if there is a Msg error
    try {
        # Show server reply
        print $serverMsg;

        # Answer to server ping requests to keep connection alive
        if ($serverMsg =~ m/^PING (.*?)$/gi)
            {sendIRC("PONG ".$1); }

        # join channel after we get the welcome msg from server
        elsif ($serverMsg =~ / 001 $botnick :/)
            {sendIRC("JOIN $homeChannel"); }

#------------
# If JOIN /
#-------------------------------------
# Messages come in from IRC in the format of: ":[Nick]!~[hostname]@[IPAddress] JOIN :[channel]"
        elsif ($serverMsg =~ / JOIN :/) {
            $nick = getNick($serverMsg);
            @msgSpt = split(/ JOIN :/, $serverMsg);
            $target = $msgSpt[1];

            if ($homeChannel = $target)
                {sendPrivMsg($nick, "Hello $nick and welcome to $homeChannel"); }
            
            # End JOIN    
            }

#------------
# If PRIVMSG /
#------------------------------------- 
# Messages come in from IRC in the format of: ":[Nick]!~[hostname]@[IPAddress] PRIVMSG [channel] :[message]"
        elsif ($serverMsg =~ / PRIVMSG /) {
            $nick = getNick($serverMsg);
            $target = getTarget($serverMsg);     
            $message = getMessage($target, $serverMsg);  

            # When msg is sent to homeChannel
            if ($homeChannel = $target && $serverMsg =~ / :!testMsg/) {
                #send msg to home channel
                sendPrivMsg($target, "found testMsg");  
                sendPrivMsg($nick, "found testMsg"); 
                }

            # When msg is sent to bot
            elsif ($botnick = $target) {
                if ($serverMsg =~ / :!testMsg/)
                    {sendPrivMsg($nick, "found testMsg"); }

                elsif ($botnick = $target && $serverMsg =~ / :hello/) 
                    {sendPrivMsg($nick, "Hello $nick, this is about all I do. Tell you welcome to the channel, reply to hello, and replay to !testMsg"); }
                    
                # End msg is sent to bot  
                }
                
            # End PRIVMSG  
            }
    } 
    catch($e) {
     warn($e);
    }


}
