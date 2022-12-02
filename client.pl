use strict;
use warnings;
use utf8;
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

sub bencode {
    no locale;
    my $item = shift;
    my $line = '';
    if(ref($item) eq 'HASH') {
        $line = 'd';
        foreach my $key (sort(keys %{$item})) {
            $line .= bencode($key);
            $line .= bencode(${$item}{$key});
        }
        $line .= 'e';
        return $line;
    }
    if(ref($item) eq 'ARRAY') {
        $line = 'l';
        foreach my $l (@{$item}) {
            $line .= bencode($l);
        }
        $line .= 'e';
        return $line;
    }
    if($item =~ /^\d+$/) {
        $line = 'i';
        $line .= $item;
        $line .= 'e';
        return $line;
    }
    $line = length($item).":";
    $line .= $item;
    return $line;
}

sub bdecode {
    my $string = shift;
    my @chunks = split(//, $string);
    my $root = _dechunk(\@chunks);
    return $root;
}

sub _dechunk {
    my $chunks = shift;

    my $item = shift(@{$chunks});
    if($item eq 'd') {
        $item = shift(@{$chunks});
        my %hash;
        while($item ne 'e') {
            unshift(@{$chunks}, $item);
            my $key = _dechunk($chunks);
            $hash{$key} = _dechunk($chunks);
            $item = shift(@{$chunks});
        }
            return \%hash;
    }
    if($item eq 'l') {
        $item = shift(@{$chunks});
        my @list;
        while($item ne 'e') {
            unshift(@{$chunks}, $item);
            push(@list, _dechunk($chunks));
            $item = shift(@{$chunks});
        }
        return \@list;
    }
    if($item eq 'i') {
        my $num;
        $item = shift(@{$chunks});
        while($item ne 'e') {
            $num .= $item;
            $item = shift(@{$chunks});
        }
        return $num;
    }
    if($item =~ /\d/) {
        my $num;
        while($item =~ /\d/) {
            $num .= $item;
            $item = shift(@{$chunks});
        }
        my $line = '';
        for(1 .. $num) {
            $line .= shift(@{$chunks});
        }
        return $line;
    }
    return $chunks;
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




    use Data::Dumper;
    print Dumper $torrent, "\n";
    print Dumper $tracker_request, "\n";
}

my $torrent_file = '/home/pc/Documents/GIT/TorrentClient/ubuntu-22.04.1-live-server-amd64.iso.torrent';
#my $torrent_file = "archlinux-2022.12.01-x86_64.iso.torrent";
main($torrent_file);
