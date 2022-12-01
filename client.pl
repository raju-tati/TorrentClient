use strict;
use warnings;
use utf8;

sub file_content() {
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


sub main() {
    my $torrent_file = 'ubuntu-22.04.1-live-server-amd64.iso.torrent';
    my $torrent      = bdecode( file_content($torrent_file) );

}
