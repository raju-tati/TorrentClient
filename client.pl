use strict;
use warnings;
use POSIX;
use Digest::SHA1 qw(sha1);
use Encode;
use Bencode qw(bencode bdecode);
use LWP::Simple qw(get);
use Try::Tiny;

sub file_content {
    my ($file) = @_;
    my $contents;
    open( my $fh, '<', $file ) or die "Cannot open torrent $file";
    {
        local $/;
        $contents = <$fh>;
    }
    close($fh);
    return $contents;
}

sub get_infoHash {
    my ($infoKey) = @_;
    my $info_hash = Encode::encode( "ISO-8859-1", sha1( bencode( $infoKey )));
    return $info_hash;
}


sub main {
    my ($torrent_file) = @_;
    my $fileContent    = file_content($torrent_file);
    my $torrent        = bdecode( $fileContent );

    my $file_name    = $torrent->{'info'}->{'name'};
    my $file_length  = $torrent->{'info'}->{'length'};
    my $piece_length = $torrent->{'info'}->{'piece length'};

    my $infoKey = $torrent->{'info'};
    my $info_hash = get_infoHash($infoKey);

    my $announce   = $torrent->{'announce'};
    my $port       = 6881;
    my $left       = $torrent->{'info'}->{'length'};
    my $uploaded   = 0;
    my $downloaded = 0;
    my $peer_id    = "-AZ2200-6wfG2wk6wWLc";

    # $tracker request from torrent file info
    my $tracker_request =
        $announce
      . "?info_hash="
      . $info_hash
      . "&peer_id="
      . $peer_id
      . "&port="
      . $port
      . "&uploaded="
      . $uploaded
      . "&downloaded="
      . $downloaded
      . "&left="
      . $left;


    my $response = get($tracker_request) or die "Cannot connect to tracker";
    my $tracker_response = bdecode($response);

    my $peers = $tracker_response->{'peers'};
    
    my $bitfields_num = length($torrent->{'info'}->{'pieces'}) / 20;
    my $bitfield_num_bytes = 4 + 1 + ceil($bitfields_num / 8);

    mkdir( 'pieces' );

    my $piece_channel = new Coro::Channel;
    for my $n (0..$bitfields_num - 1) {
        $piece_channel->put($n);
    }

    tcp_connect $peers->[0]->{'ip'}, $peers->[0]->{'port'}, Coro::rouse_cb;
    my $fh = unblock +(Coro::rouse_wait)[0];

    my $buf;
    my $bitfield;

    my $pstr = "BitTorrent protocol";
    my $message = pack 'C1A*a8a20a20', length($pstr), $pstr, '',  $info_hash, $peer_id;
    
    try {
        $fh->syswrite($message);
    } 
	catch {
        terminate;
    };
}

my $torrent_file = 'debian-11.6.0-amd64-netinst.iso.torrent';
main($torrent_file);
